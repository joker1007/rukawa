module Rukawa::State
  def self.get(name)
    const_get(name.to_s.capitalize)
  end

  module BaseExt
    def state_name
      @state_name ||= to_s.gsub(/Rukawa::State::/, "").downcase
    end

    def colored
      Paint[state_name.to_s, color]
    end
  end

  module Running
    extend BaseExt

    def name
      :running
    end

    def self.color
      :cyan
    end
  end

  module Skipped
    extend BaseExt

    def self.color
      :yellow
    end
  end

  module Error
    extend BaseExt

    def self.color
      :red
    end
  end

  module Waiting
    extend BaseExt

    def self.color
      :default
    end
  end

  module Finished
    extend BaseExt

    def self.color
      :green
    end
  end
end
