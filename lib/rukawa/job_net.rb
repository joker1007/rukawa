require 'rukawa/dag_node'

module Rukawa
  class JobNet
    include DagNode
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

    private

    def children_errors
      inner_dataflows.map(&:reason).compact
    end
  end
end
