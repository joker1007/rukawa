module Rukawa
  class JobNet
    attr_accessor :in_jobs, :out_jobs
    attr_reader :dag, :state, :futures
    STATES = %i(waiting running finished error).freeze

    class << self
      def dependencies
        raise NotImplementedError, "Please override"
      end
    end

    def initialize(variables = {})
      @variables = variables
      @dag = Dag.new(self.class.dependencies)
      @in_jobs = []
      @out_jobs = []
      @state = :waiting
    end

    def depend(job)
      job.out_jobs << self
      self.in_jobs << job
    end

    def dataflow
      return @dataflow if @dataflow

      @dataflow = Concurrent.dataflow(*depend_dataflows) do |*results|
        Rukawa.logger.info("Start #{self.class}")
        @state = :running
        begin
          raise DependentJobFailure unless results.all?
          run
          unless errors.empty?
            raise ChildrenJobFailure
          end
        rescue => e
          Rukawa.logger.error("Error #{self.class} by #{e}")
          @state = :error
          raise
        end
        Rukawa.logger.info("Finish #{self.class}")
        @state = :finished
        true
      end
    end

    def inner_dataflows
      @dag.map(&:dataflow)
    end

    def run
      inner_dataflows.map(&:execute).each(&:wait)
    end

    def complete?
      dataflow.complete?
    end

    private

    def depend_dataflows
      @in_jobs.map(&:dataflow)
    end

    def errors
      inner_dataflows.map(&:reason).compact
    end
  end
end
