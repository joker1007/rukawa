require 'rukawa/abstract_job'

module Rukawa
  class JobNet < AbstractJob
    include Enumerable
    attr_reader :dag, :context, :variables

    class << self
      def dependencies
        raise NotImplementedError, "Please override"
      end
    end

    def initialize(parent_job_net, variables, context, *resume_job_classes)
      @parent_job_net = parent_job_net
      @variables = variables
      @context = context
      @dag = Dag.new
      @dag.build(self, variables, context, self.class.dependencies)
      @resume_job_classes = resume_job_classes

      unless resume_job_classes.empty?
        resume_targets = []
        @dag.tsort_each_node do |node|
          node.set_state(:bypassed)
          resume_targets << node if resume_job_classes.include?(node.class)
        end

        resume_targets.each do |node|
          @dag.each_strongly_connected_component_from(node) do |nodes|
            nodes.each { |connected| connected.set_state(:waiting) }
          end
        end
      end
    end

    def execute
      dataflows.each(&:execute)
    end

    def run(wait_interval = 1)
      promise = Concurrent::Promise.new do
        futures = execute
        until futures.all?(&:complete?)
          yield self if block_given?
          sleep wait_interval
        end
        errors = futures.map(&:reason).compact

        unless errors.empty?
          errors.each do |err|
            next if err.is_a?(DependencyUnsatisfied)
            Rukawa.logger.error(err)
          end
        end

        futures
      end
      promise.execute
    end

    def started_at
      @dag.nodes.min_by { |j| j.started_at ? j.started_at.to_i : Float::INFINITY }.started_at
    end

    def finished_at
      @dag.nodes.max_by { |j| j.finished_at.to_i }.finished_at
    end

    def toplevel?
      @parent_job_net.nil?
    end

    def subgraph?
      !toplevel?
    end

    def dataflows
      @dag.leveled_each.map(&:dataflow)
    end

    def state
      inject(Rukawa::State::Waiting) do |state, j|
        state.merge(j.state)
      end
    end

    def output_dot(filename, format: nil)
      if format && format != "dot"
        io = IO.popen(["#{Rukawa.config.dot_command}", "-T#{format}", "-o", filename], "w")
        io.write(to_dot)
        io.close
      else
        File.open(filename, 'w') { |f| f.write(to_dot) }
      end
    end

    def to_dot(subgraph = false)
      graphdef = subgraph ? "subgraph" : "digraph"
      buf = %Q|#{graphdef} "#{subgraph ? "cluster_" : ""}#{name}" {\n|
      buf += %Q{label = "#{graph_label}";\n}
      buf += Rukawa.config.graph.attrs
      buf += Rukawa.config.graph.node.attrs
      buf += "color = blue;\n" if subgraph
      dag.each do |j|
        buf += j.to_dot_def
      end

      dag.edges.each do |edge|
        buf += %Q|"#{edge.from.name}" -> "#{edge.to.name}";\n|
      end
      buf += "}\n"
    end

    def to_dot_def
      to_dot(true)
    end

    def jobs_as_to
      @dag.jobs.select { |j| j.in_comings.select { |edge| edge.cluster == self }.empty? && j.root? }
    end

    def jobs_as_from
      @dag.jobs.select { |j| j.out_goings.select { |edge| edge.cluster == self }.empty? && j.leaf? }
    end

    def each(&block)
      @dag.each(&block)
    end

    private

    def graph_label
      if @resume_job_classes.empty?
        name
      else
        "#{name} resume from (#{@resume_job_classes.join(", ")})"
      end
    end
  end
end
