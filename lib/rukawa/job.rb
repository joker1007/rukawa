require 'concurrent'
require 'rukawa/abstract_job'

module Rukawa
  class Job < AbstractJob
    attr_accessor :in_comings, :out_goings
    attr_reader :state, :started_at, :finished_at

    class << self
      attr_reader :retryable, :retry_limit, :retry_exception_type, :retry_wait
      def set_retryable(limit: 8, type: nil, wait: nil)
        @retryable = true
        @retry_limit = limit
        @retry_exception_type = type
        @retry_wait = wait
      end

      def set_dependency_type(name)
        @dependency_type = Rukawa::Dependency.get(name)
      end

      def dependency_type
        @dependency_type || Rukawa::Dependency.get(:all_success)
      end
    end

    def initialize(parent_job_net)
      @parent_job_net = parent_job_net
      @in_comings = Set.new
      @out_goings = Set.new
      @retry_count = 0
      @retry_wait = 1
      set_state(:waiting)
    end

    def set_state(name)
      @state = Rukawa::State.get(name)
    end

    def root?
      in_comings.select { |edge| edge.cluster == @parent_job_net }.empty?
    end

    def leaf?
      out_goings.select { |edge| edge.cluster == @parent_job_net }.empty?
    end

    def dataflow
      return @dataflow if @dataflow
      return @dataflow = bypass_dataflow if @state.bypassed?

      @dataflow = Concurrent.dataflow_with(Rukawa.executor, *depend_dataflows) do |*results|
        do_run(*results)
        @state
      end
    end

    def run
    end

    private def do_run(*results)
      @started_at = Time.now
      check_dependencies(results)

      if skip?
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
      handle_error(e)
      Rukawa.logger.error("Retry #{self.class}")
      retry
    ensure
      @finished_at = Time.now
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

    def bypass_dataflow
      Concurrent.dataflow_with(Rukawa.executor, *depend_dataflows) do |*results|
        Rukawa.logger.info("Skip #{self.class}")
        @state
      end
    end

    def dependency_type
      self.class.dependency_type
    end

    def check_dependencies(results)
      dependency = dependency_type.new(*results)
      unless dependency.resolve
        set_state(:aborted)
        raise DependencyUnsatisfied
      end
    end

    def handle_error(e)
      Rukawa.logger.error("Error #{self.class} by #{e}")
      if retry?(e)
        @retry_count += 1
        set_state(:waiting)
        sleep @retry_wait
        @retry_wait = self.class.retry_wait ? self.class.retry_wait : @retry_wait * 2
      else
        set_state(:error) unless e.is_a?(DependencyUnsatisfied)
        raise e
      end
    end

    def retry?(e)
      return false unless self.class.retryable

      type_condition = case self.class.retry_exception_type
      when Array
        self.class.retry_exception_type.include?(e.class)
      when Class
        e.is_a?(self.class.retry_exception_type)
      when nil
        !e.is_a?(DependencyUnsatisfied)
      end

      type_condition && (self.class.retry_limit.nil? || self.class.retry_limit == 0 || @retry_count < self.class.retry_limit)
    end

    def store(key, value)
      Rukawa.store[self.class] ||= Concurrent::Hash.new
      Rukawa.store[self.class][key] = value
    end
  end
end
