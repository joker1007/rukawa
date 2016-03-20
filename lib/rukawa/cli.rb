require 'thor'
require 'rukawa/runner'

module Rukawa
  class Cli < Thor
    desc "run", "Run jobnet"
    map "run" => "_run"
    method_option :concurrency, aliases: "-c", type: :numeric, default: nil, desc: "Default: cpu count"
    method_option :variables, type: :hash, default: {}
    method_option :job_dirs, type: :array, default: [], desc: "Load job directories"
    method_option :batch, aliases: "-b", type: :boolean, default: false, desc: "If batch mode, not display running status"
    method_option :log, aliases: "-l", type: :string, default: "./rukawa.log"
    method_option :refresh, aliases: "-r", type: :numeric, default: 3, desc: "Refresh interval for running status information"
    def _run(job_net_name)
      Rukawa.configure do |c|
        c.log_file = options[:log]
        c.concurrency = options[:concurrency] if options[:concurrency]
      end
      load_job_definitions

      job_net_class = Object.const_get(job_net_name)
      job_net = job_net_class.new(options[:variables])
      result = Runner.run(job_net, options[:batch])
      exit 1 unless result
    end

    desc "graph", "Output jobnet graph"
    method_option :job_dirs, type: :array, default: []
    method_option :output, aliases: "-o", type: :string, required: true
    def graph(job_net_name)
      load_job_definitions

      job_net_class = Object.const_get(job_net_name)
      job_net = job_net_class.new(options[:variables])
      job_net.output_dot(options[:format], options[:output])
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
