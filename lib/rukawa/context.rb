module Rukawa
  class Context
    attr_reader :store, :executor, :semaphore

    def initialize(currency = nil)
      @store = Concurrent::Hash.new
      @executor = Concurrent::FixedThreadPool.new(currency || Rukawa.config.concurrency)
      @executor.auto_terminate = true
      @semaphore = Concurrent::Semaphore.new(currency || Rukawa.config.concurrency)
    end

    def shutdown
      @executor.shutdown if @executor.running?
    end
  end
end
