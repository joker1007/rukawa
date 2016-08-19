require "concurrent"

module Rukawa
  class << self
    def logger
      config.logger
    end

    def configure
      yield config
    end

    def config
      Configuration.instance
    end

    def load_jobs
      job_dirs = config.job_dirs.map { |d| File.expand_path(d) }.uniq
      job_dirs.each do |dir|
        Dir.glob(File.join(dir, "**/*.rb")) { |f| load f }
      end
    end
  end
end

require 'active_support'
require "rukawa/version"
require 'rukawa/context'
require 'rukawa/errors'
require 'rukawa/state'
require 'rukawa/dependency'
require 'rukawa/configuration'
require 'rukawa/job_net'
require 'rukawa/job'
require 'rukawa/dag'
require 'rukawa/wrapper/active_job'
