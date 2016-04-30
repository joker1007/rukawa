require "concurrent"

module Rukawa
  class << self
    def init
      unless @initialized
        @store = Concurrent::Hash.new
        @executor = Concurrent::FixedThreadPool.new(config.concurrency)
        @semaphore = Concurrent::Semaphore.new(config.concurrency)
        @initialized = true
      end
    end
    attr_reader :store, :executor, :semaphore

    def logger
      config.logger
    end

    def configure
      yield config
    end

    def config
      Configuration.instance
    end
  end
end

require 'active_support'
require "rukawa/version"
require 'rukawa/errors'
require 'rukawa/state'
require 'rukawa/dependency'
require 'rukawa/configuration'
require 'rukawa/job_net'
require 'rukawa/job'
require 'rukawa/dag'
