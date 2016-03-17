require 'thor'
require 'rukawa/runner'

module Rukawa
  class Cli < Thor
    desc "run", "Run jobnet"
    map "run" => "_run"
    method_option :concurrency, aliases: "-c", type: :numeric, default: nil
    method_option :variables, type: :hash, default: {}
    method_option :job_dirs, type: :array, default: []
    method_option :batch, aliases: "-b", type: :boolean, default: false
    def _run(job_net_name)
      load_job_definitions

      job_net_class = Object.const_get(job_net_name)
      job_net = job_net_class.new(options[:variables])
      Runner.run(job_net, options[:batch])
    end

    private

    def default_job_dirs
      [File.join(Dir.pwd, "job_nets"), File.join(Dir.pwd, "jobs")]
    end

    def load_job_definitions
      job_dirs = (default_job_dirs + options[:job_dirs]).map { |d| File.expand_path(d) }.uniq
      job_dirs.each do |dir|
        Dir.glob(File.join(dir, "**/*.rb")) { |f| load f }
      end
    end
  end
end
