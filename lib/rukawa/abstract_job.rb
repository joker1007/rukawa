require 'set'
require 'rukawa/state'
require 'active_support/core_ext/class'

module Rukawa
  class AbstractJob
    attr_reader :parent_job_net

    class_attribute :skip_rules, instance_writer: false
    self.skip_rules = []
    class << self
      def add_skip_rule(callable_or_symbol)
        self.skip_rules = skip_rules + [callable_or_symbol]
      end

      def description
        @description
      end
      alias :desc :description

      def set_description(body)
        @description = body
      end
      alias :set_desc :set_description
    end

    def name
      self.class.to_s
    end

    def inspect
      to_s
    end

    def skip?
      parent_skip = @parent_job_net ? @parent_job_net.skip? : false
      parent_skip || skip_rules.inject(false) do |cond, rule|
        cond || rule.is_a?(Symbol) ? method(rule).call : rule.call(self)
      end
    end

    def elapsed_time_from(time = Time.now)
      return finished_at - started_at if started_at && finished_at
      return time - started_at if started_at

      nil
    end

    def formatted_elapsed_time_from(time = Time.now)
      elapsed = elapsed_time_from(time)
      return "N/A" unless elapsed

      hour = elapsed.to_i / 3600
      min = elapsed.to_i / 60
      sec = (elapsed - hour * 3600 - min * 60).to_i

      hour_format = min > 0 ? "%dh " % hour : ""
      min_format = min > 0 ? "%dm " % min : ""
      sec_format = "#{sec}s"
      "#{hour_format}#{min_format}#{sec_format}"
    end
  end
end
