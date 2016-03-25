require 'set'
require 'rukawa/state'

module Rukawa
  class AbstractJob
    attr_reader :parent_job_net

    class << self
      def skip_rules
        @skip_rules ||= []
      end

      def add_skip_rule(callable_or_symbol)
        skip_rules.push(callable_or_symbol)
      end
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

    def skip_rules
      self.class.skip_rules
    end

    def elapsed_time_from(time = Time.now)
      return finished_at - started_at if started_at && finished_at
      return time - started_at if started_at

      nil
    end

    def formatted_elapsed_time_from(time = Time.now)
      sec = elapsed_time_from(time)
      return "N/A" unless sec

      hour = sec.to_i / 3600
      min = sec.to_i / 60

      hour_format = min > 0 ? "%dh " % hour : ""
      min_format = min > 0 ? "%dm " % min : ""
      sec_format = "#{sec.to_i}s"
      "#{hour_format}#{min_format}#{sec_format}"
    end
  end
end
