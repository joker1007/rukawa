module Rukawa
  module DagNode
    def self.included(klass)
      klass.module_eval do
        attr_accessor :in_jobs, :out_jobs
        attr_reader :state
      end
    end

    def initialize(*)
      @in_jobs = []
      @out_jobs = []
      @state = :waiting
    end

    def depend(job)
      job.out_jobs << self
      self.in_jobs << job
    end

    def root?
      @in_jobs.empty?
    end

    def leaf?
      @out_jobs.empty?
    end

    def name
      self.class.to_s
    end

    def dataflow
      return @dataflow if @dataflow

      @dataflow = Concurrent.dataflow(*depend_dataflows) do |*results|
        Rukawa.logger.info("Start #{self.class}")
        @state = :running
        begin
          raise DependentJobFailure unless results.all?
          run
          unless children_errors.empty?
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

    def run
      raise NotImplementedError, "Please override"
    end

    def complete?
      dataflow.complete?
    end

    private

    def depend_dataflows
      @in_jobs.map(&:dataflow)
    end

    def children_errors
      []
    end
  end
end
