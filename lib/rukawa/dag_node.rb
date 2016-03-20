module Rukawa
  module DagNode
    def self.included(klass)
      klass.module_eval do
        attr_accessor :in_jobs, :out_jobs
        attr_reader :state
      end
      klass.extend(ClassMethods)
    end

    module ClassMethods
      def skip_rules
        @skip_rules ||= []
      end

      def add_skip_rule(callable_or_symbol)
        skip_rules.push(callable_or_symbol)
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
        begin
          raise DependentJobFailure unless results.all? { |r| !r.nil? }

          if skip? || results.any? { |r| r == :skipped }
            Rukawa.logger.info("Skip #{self.class}")
            @state = :skipped
          else
            Rukawa.logger.info("Start #{self.class}")
            @state = :running
            run
            unless children_errors.empty?
              raise ChildrenJobFailure
            end

            Rukawa.logger.info("Finish #{self.class}")
            @state = :finished
          end
        rescue => e
          Rukawa.logger.error("Error #{self.class} by #{e}")
          @state = :error
          raise
        end

        @state
      end
    end

    def run
      raise NotImplementedError, "Please override"
    end

    def complete?
      dataflow.complete?
    end

    def skip?
      skip_rules.inject(false) do |cond, rule|
        cond || rule.is_a?(Symbol) ? method(rule).call : rule.call(self)
      end
    end

    private

    def depend_dataflows
      @in_jobs.map(&:dataflow)
    end

    def children_errors
      []
    end

    def skip_rules
      self.class.skip_rules
    end
  end
end
