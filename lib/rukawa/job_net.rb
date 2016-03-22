require 'rukawa/abstract_job'

module Rukawa
  class JobNet < AbstractJob
    include Enumerable
    attr_reader :parent_job_net, :dag

    class << self
      def dependencies
        raise NotImplementedError, "Please override"
      end
    end

    def initialize(parent_job_net, *resume_job_classes)
      @parent_job_net = parent_job_net
      @dag = Dag.new
      @dag.build(self, self.class.dependencies)
    end

    def toplevel?
      @parent_job_net.nil?
    end

    def subgraph?
      !toplevel?
    end

    def dataflows
      flat_map do |j|
        if j.respond_to?(:dataflows)
          j.dataflows
        else
          [j.dataflow]
        end
      end
    end

    def state
      inject(Rukawa::State::Waiting) do |state, j|
        state.merge(j.state)
      end
    end

    def output_dot(filename)
      File.open(filename, 'w') { |f| f.write(to_dot) }
    end

    def to_dot(subgraph = false)
      graphdef = subgraph ? "subgraph" : "digraph"
      buf = %Q|#{graphdef} "#{subgraph ? "cluster_" : ""}#{name}" {\n|
      buf += %Q{label = "#{name}";\n}
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
  end
end
