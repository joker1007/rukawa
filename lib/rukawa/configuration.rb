require 'singleton'
require 'ostruct'
require 'delegate'
require 'concurrent'

module Rukawa
  class Configuration < Delegator
    include Singleton

    def initialize
      @config = OpenStruct.new(log_file: "./rukawa.log", concurrency: Concurrent.processor_count)
    end

    def __getobj__
      @config
    end
  end
end
