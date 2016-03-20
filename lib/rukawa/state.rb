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

    def merge(other)
      other
    end
  end

  module Running
    extend BaseExt

    def self.color
      :cyan
    end

    def self.merge(_other)
      self
    end
  end

  module Skipped
    extend BaseExt

    def self.color
      :yellow
    end

    def self.merge(other)
      if other == Finished
        self
      else
        other
      end
    end
  end

  module Error
    extend BaseExt

    def self.color
      :red
    end

    def self.merge(other)
      if other == Running
        other
      else
        self
      end
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
