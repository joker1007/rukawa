require 'rukawa/dag_node'

module Rukawa
  class JobNet
    include DagNode
    include Enumerable
    attr_reader :dag

    class << self
      def dependencies
        raise NotImplementedError, "Please override"
      end
    end

    def initialize(variables = {})
      super
      @variables = variables
      @dag = Dag.new(self.class.dependencies)
    end

    def inner_dataflows
      @dag.map(&:dataflow)
    end

    def run
      inner_dataflows.each(&:execute).each(&:wait)
    end

    def output_dot(filename)
      File.open(filename, 'w') { |f| f.write(to_dot) }
    end

    def to_dot(subgraph = false)
      graphdef = subgraph ? "subgraph" : "digraph"
      buf = "#{graphdef} #{subgraph ? "cluster_" : ""}#{name} {\n"
      buf += %Q{label = "#{name}";\n}
      buf += "color = blue;\n" if subgraph
      @dag.each do |j|
        if j.is_a?(JobNet)
          buf += j.to_dot(true)
        end

        if j.is_a?(Job)
          buf += "#{j.name} [color = #{j.state.color}];\n" unless j.state == Rukawa::State::Waiting
        end

        j.out_jobs.each do |_j|
          if j.is_a?(JobNet)
            from_nodes = j.dag.leaves.map(&:name)
          else
            from_nodes = Array(j.name)
          end

          if _j.is_a?(JobNet)
            to_nodes = _j.dag.root.out_jobs.map(&:name)
          else
            to_nodes = Array(_j.name)
          end

          from_nodes.each do |from|
            to_nodes.each do |to|
              buf += "#{from} -> #{to};\n"
            end
          end
        end
      end
      buf += "}\n"
    end

    def root
      @dag.root
    end

    def leaves
      @dag.leaves
    end

    def each(&block)
      @dag.each(&block)
    end

    private

    def children_errors
      inner_dataflows.map(&:reason).compact
    end
  end
end
