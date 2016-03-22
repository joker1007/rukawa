require 'concurrent'
require 'rukawa/abstract_job'

module Rukawa
  class Job < AbstractJob
    attr_accessor :in_comings, :out_goings
    attr_reader :state

    def initialize(parent_job_net)
      @parent_job_net = parent_job_net
      @in_comings = Set.new
      @out_goings = Set.new
      set_state(:waiting)
    end

    def root?
      in_comings.select { |edge| edge.cluster == @parent_job_net }.empty?
    end

    def leaf?
      out_goings.select { |edge| edge.cluster == @parent_job_net }.empty?
    end

    def dataflow
      return @dataflow if @dataflow

      @dataflow = Concurrent.dataflow_with(Rukawa.executor, *depend_dataflows) do |*results|
        begin
          raise DependentJobFailure unless results.all? { |r| !r.nil? }

          if skip? || results.any? { |r| r == Rukawa::State.get(:skipped) }
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

    def run
    end

    def jobs_as_from
      [self]
    end
    alias :jobs_as_to :jobs_as_from

    def to_dot_def
      if state == Rukawa::State::Waiting
        "#{name};\n"
      else
        "#{name} [style = filled,fillcolor = #{state.color}];\n"
      end
    end

    private

    def depend_dataflows
      in_comings.map { |edge| edge.from.dataflow }
    end

    def set_state(name)
      @state = Rukawa::State.get(name)
    end

    def store(key, value)
      Rukawa.store[self.class] ||= Concurrent::Hash.new
      Rukawa.store[self.class][key] = value
    end
  end
end
