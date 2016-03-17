module Rukawa
  class JobNet
    attr_reader :dag

    def initialize(variables)
      @variables = variables
      @dag = Dag.new(self.class.dependencies)
    end

    def run
      @dag.leaves.map { |leaf_job| leaf_job.dataflow.execute }
    end

    class << self
      def dependencies
        raise NotImplementedError, "Please override"
      end
    end
  end
end
