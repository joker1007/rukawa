require 'concurrent'
require 'rukawa/abstract_job'

module Rukawa
  class Job < AbstractJob
    attr_accessor :in_comings, :out_goings
    attr_reader :state

    def initialize(job_net)
      @job_net = job_net
      @in_comings = Set.new
      @out_goings = Set.new
      set_state(:waiting)
    end

    def root?
      in_comings.empty?
    end

    def leaf?
      out_goings.empty?
    end

    def set_state(name)
      @state = Rukawa::State.get(name)
    end

    def store(key, value)
      Rukawa.store[self.class] ||= Concurrent::Hash.new
      Rukawa.store[self.class][key] = value
    end

    def dataflow
      return @dataflow if @dataflow

      @dataflow = Concurrent.dataflow_with(executor, *depend_dataflows) do |*results|
        begin
          raise DependentJobFailure unless results.all? { |r| !r.nil? }

          if skip? || @job_net.skip? || results.any? { |r| r == Rukawa::State.get(:skipped) }
            Rukawa.logger.info("Skip #{self.class}")
            set_state(:skipped)
          else
            Rukawa.logger.info("Start #{self.class}")
            set_state(:running)
            run
            Rukawa.logger.info("Finish #{self.class}")
            set_state(:finished)
          end
        rescue => e
          Rukawa.logger.error("Error #{self.class} by #{e}")
          set_state(:error)
          raise
        end

        @state
      end
    end

    def complete?
      dataflow.complete?
    end

    def run
    end

    def nodes_as_from
      [self]
    end

    def nodes_as_to
      [self]
    end

    def to_dot_def
      if state == Rukawa::State::Waiting
        ""
      else
        "#{name} [color = #{state.color}];\n" unless state == Rukawa::State::Waiting
      end
    end

    def executor
      Rukawa.executor
    end

    private

    def depend_dataflows
      in_comings.map { |edge| edge.from.dataflow }
    end
  end
end
