module Rukawa
  module Dependency
    def self.get(name)
      const_get(name.to_s.split("_").map(&:capitalize).join)
    end

    class Base
      def initialize(*results)
        @results = results
      end

      def resolve
        raise NotImplementedError
      end
    end

    class AllSuccess < Base
      def resolve
        @results.all? { |r| r && r.success? }
      end
    end

    class AllDone < Base
      def resolve
        true
      end
    end

    class OneSuccess < Base
      def resolve
        @results.empty? || @results.any? { |r| r && r.success? }
      end
    end

    class AllSuccessOrSkipped < Base
      def resolve
        @results.all? { |r| r && (r.success? || r.skipped?) }
      end
    end

    class OneSuccessOrSkipped < Base
      def resolve
        @results.empty? || @results.any? { |r| r && (r.success? || r.skipped?) }
      end
    end

    class AllFailed < Base
      def resolve
        @results.none? { |r| r }
      end
    end

    class OneFailed < Base
      def resolve
        @results.empty? || @results.any? { |r| r.nil? }
      end
    end
  end
end
