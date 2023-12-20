module Rukawa
  class Context
    attr_reader :store, :executor, :semaphore, :concurrency

    def initialize(concurrency = nil)
      @concurrency = concurrency || Rukawa.config.concurrency
      @store = Concurrent::Hash.new
      @executor = Concurrent::CachedThreadPool.new
      @semaphore = Concurrent::Semaphore.new(@concurrency)
    end

    def shutdown
      @executor.shutdown if @executor.running?
    end
  end
end
