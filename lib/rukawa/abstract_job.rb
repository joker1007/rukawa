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
  end
end
