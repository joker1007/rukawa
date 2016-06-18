require 'concurrent'
require 'rukawa/abstract_job'
require 'rukawa/dependency'
require 'rukawa/state'
require 'active_support/core_ext/class'
require 'active_support/callbacks'

module Rukawa
  class Job < AbstractJob
    include ActiveSupport::Callbacks
    define_callbacks :run,
      terminator: ->(_,result) { result == false },
      skip_after_callbacks_if_terminated: true,
      scope: [:kind, :name],
      only: [:before, :around, :after]

    define_callbacks :fail,
      terminator: ->(_,result) { result == false },
      skip_after_callbacks_if_terminated: true,
      scope: [:kind, :name],
      only: [:after]

    attr_accessor :in_comings, :out_goings
    attr_reader :state, :started_at, :finished_at, :variables

    class_attribute :retryable, :retry_limit, :retry_exception_type, :retry_wait, instance_writer: false
    class_attribute :dependency_type, instance_writer: false
    class_attribute :resource_count, instance_reader: false, instance_writer: false
    self.dependency_type = Dependency::AllSuccess
    self.resource_count = 1

    class << self
      def set_retryable(limit: 8, type: nil, wait: nil)
        self.retryable = true
        self.retry_limit = limit
        self.retry_exception_type = type
        self.retry_wait = wait
      end

      def set_dependency_type(name)
        self.dependency_type = Rukawa::Dependency.get(name)
      end

      def set_resource_count(count)
        self.resource_count = count
      end

      def before_run(*args, **options, &block)
        set_callback :run, :before, *args, **options, &block
      end

      def after_run(*args, **options, &block)
        options[:prepend] = true
        conditional = ActiveSupport::Callbacks::Conditionals::Value.new { |v|
          v != false
        }
        options[:if] = Array(options[:if]) << conditional
        set_callback :run, :after, *args, **options, &block
      end

      def after_fail(*args, **options, &block)
        options[:prepend] = true
        conditional = ActiveSupport::Callbacks::Conditionals::Value.new { |v|
          v != false
        }
        options[:if] = Array(options[:if]) << conditional
        set_callback :fail, :after, *args, **options, &block
      end

      def around_run(*args, **options, &block)
        set_callback :run, :around, *args, **options, &block
      end
    end

    around_run :acquire_resource

    around_run do |_, blk|
      Rukawa.logger.info("Start #{self.class}")
      blk.call
      Rukawa.logger.info("Finish #{self.class}")
    end

    around_run do |_, blk|
      set_state(:running)
      blk.call
      set_state(:finished)
    end

    def initialize(parent_job_net, variables)
      @parent_job_net = parent_job_net
      @variables = variables
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

      if skip?
        Rukawa.logger.info("Skip #{self.class}")
        set_state(:skipped)
      else
        check_dependencies(results)
        run_callbacks :run do
          run
        end
      end
    rescue => e
      run_callbacks :fail
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

    def resource_count
      [self.class.resource_count, Rukawa.config.concurrency].min
    end

    def acquire_resource
      Rukawa.semaphore.acquire(resource_count)
      yield
    ensure
      Rukawa.semaphore.release(resource_count)
    end
  end
end
