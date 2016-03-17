require 'concurrent'

module Rukawa
  class Job
    class ParentJobFailure < StandardError; end

    attr_accessor :in_jobs, :out_jobs

    def initialize
      @in_jobs = []
      @out_jobs = []
    end

    def depend(job)
      job.out_jobs << self
      self.in_jobs << job
    end

    def dataflow
      return @dataflow if @dataflow

      @dataflow = Concurrent.dataflow_with(Rukawa.executor, *depend_dataflows) do |*results|
        Rukawa.logger.info("Start #{self.class}")
        begin
          raise ParentJobFailure unless results.all?
          run
        rescue => e
          Rukawa.logger.error("Error #{self.class} by #{e}")
          raise
        end
        Rukawa.logger.info("Finish #{self.class}")
        true
      end
    end

    def state
      return nil unless @dataflow

      @dataflow.state
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
