require "concurrent"

module Rukawa
  class << self
    def logger
      @logger ||= Logger.new(config.log_file)
    end

    def store
      @store ||= Concurrent::Hash.new
    end

    def configure
      yield config
    end

    def config
      Configuration.instance
    end

    def executor
      @executor ||= Concurrent::FixedThreadPool.new(config.concurrency)
    end
  end
end

require "rukawa/version"
require 'rukawa/configuration'
require 'rukawa/job_net'
require 'rukawa/job'
require 'rukawa/dag'
