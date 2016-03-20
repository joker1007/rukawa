require 'rukawa/abstract_job'

module Rukawa
  class JobNet < AbstractJob
    include Enumerable
    attr_reader :dag

    class << self
      def dependencies
        raise NotImplementedError, "Please override"
      end
    end

    def initialize(variables = {})
      @variables = variables
      @dag = Dag.new(self, self.class.dependencies)
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

    def nodes_as_from
      leaves
    end

    def nodes_as_to
      roots
    end

    def to_dot(subgraph = false)
      graphdef = subgraph ? "subgraph" : "digraph"
      buf = "#{graphdef} #{subgraph ? "cluster_" : ""}#{name} {\n"
      buf += %Q{label = "#{name}";\n}
      buf += "color = blue;\n" if subgraph
      dag.each do |j|
        buf += j.to_dot_def
      end

      dag.edges.each do |edge|
        buf += "#{edge.from.name} -> #{edge.to.name};\n"
      end
      buf += "}\n"
    end

    def to_dot_def
      to_dot(true)
    end

    def roots
      @dag.roots
    end

    def leaves
      @dag.leaves
    end

    def each(&block)
      @dag.each(&block)
    end
  end
end
