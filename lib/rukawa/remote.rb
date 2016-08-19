module Rukawa
  module Remote
    class << self
      def store
        Rukawa.config.status_store
      end
    end
  end
end
