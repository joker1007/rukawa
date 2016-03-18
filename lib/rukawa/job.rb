require 'concurrent'

module Rukawa
  class Job
    attr_accessor :in_jobs, :out_jobs
    attr_reader :state
    STATES = %i(waiting running finished error).freeze

    def initialize
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

      @dataflow = Concurrent.dataflow_with(Rukawa.executor, *depend_dataflows) do |*results|
        Rukawa.logger.info("Start #{self.class}")
        @state = :running
        begin
          raise DependentJobFailure unless results.all?
          run
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

    def store(key, value)
      Rukawa.store[self.class] ||= Concurrent::Hash.new
      Rukawa.store[self.class][key] = value
    end

    def root?
      @in_jobs.empty?
    end

    def leaf?
      @out_jobs.empty?
    end

    def complete?
      dataflow.complete?
    end

    def run
    end

    private

    def depend_dataflows
      @in_jobs.map(&:dataflow)
    end
  end

  class RootJob < Job
    def dataflow
      return @dataflow if @dataflow

      @dataflow = Concurrent.dataflow_with(Rukawa.executor, *depend_dataflows) do |*results|
        true
      end
    end
  end
end
