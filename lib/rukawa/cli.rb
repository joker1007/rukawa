require 'thor'
require 'rukawa/runner'
require 'rukawa/overview'

module Rukawa
  class Cli < Thor
    desc "run JOB_NET_NAME [JOB_NAME] [JOB_NAME] ...", "Run jobnet. If JOB_NET is set, resume from JOB_NAME"
    map "run" => "_run"
    method_option :concurrency, aliases: "-c", type: :numeric, default: nil, desc: "Default: cpu count"
    method_option :variables, type: :hash, default: {}
    method_option :config, type: :string, default: nil, desc: "If this options is not set, try to load ./rukawa.rb"
    method_option :job_dirs, type: :array, default: [], desc: "Load job directories"
    method_option :batch, aliases: "-b", type: :boolean, default: false, desc: "If batch mode, not display running status"
    method_option :log, aliases: "-l", type: :string, default: nil
    method_option :stdout, type: :boolean, default: false, desc: "Output log to stdout"
    method_option :dot, aliases: "-d", type: :string, default: nil, desc: "Output job status by dot format"
    method_option :refresh_interval, aliases: "-r", type: :numeric, default: 3, desc: "Refresh interval for running status information"
    def _run(job_net_name, *job_name)
      load_config
      Rukawa.configure do |c|
        c.log_file = options[:stdout] ? $stdout : options[:log] || Rukawa.config.log_file
        c.concurrency = options[:concurrency] if options[:concurrency]
      end
      load_job_definitions

      job_net_class = Object.const_get(job_net_name)
      job_classes = job_name.map { |name| Object.const_get(name) }
      job_net = job_net_class.new(nil, *job_classes)
      result = Runner.run(job_net, options[:batch], options[:refresh_interval])

      if options[:dot]
        job_net.output_dot(options[:dot])
      end

      exit 1 unless result
    end

    desc "graph JOB_NET_NAME [JOB_NAME] [JOB_NAME] ...", "Output jobnet graph. If JOB_NET is set, simulate resumed job sequence"
    method_option :config, type: :string, default: nil, desc: "If this options is not set, try to load ./rukawa.rb"
    method_option :job_dirs, type: :array, default: []
    method_option :output, aliases: "-o", type: :string, required: true
    def graph(job_net_name, *job_name)
      load_config
      load_job_definitions

      job_net_class = Object.const_get(job_net_name)
      job_classes = job_name.map { |name| Object.const_get(name) }
      job_net = job_net_class.new(nil, *job_classes)
      job_net.output_dot(options[:output])
    end

    desc "run_job JOB_NAME [JOB_NAME] ...", "Run specific jobs."
    method_option :concurrency, aliases: "-c", type: :numeric, default: nil, desc: "Default: cpu count"
    method_option :variables, type: :hash, default: {}
    method_option :config, type: :string, default: nil, desc: "If this options is not set, try to load ./rukawa.rb"
    method_option :job_dirs, type: :array, default: [], desc: "Load job directories"
    method_option :batch, aliases: "-b", type: :boolean, default: false, desc: "If batch mode, not display running status"
    method_option :log, aliases: "-l", type: :string, default: nil
    method_option :stdout, type: :boolean, default: false, desc: "Output log to stdout"
    method_option :dot, aliases: "-d", type: :string, default: nil, desc: "Output job status by dot format"
    method_option :refresh_interval, aliases: "-r", type: :numeric, default: 3, desc: "Refresh interval for running status information"
    def run_job(*job_name)
      load_config
      Rukawa.configure do |c|
        c.log_file = options[:stdout] ? $stdout : options[:log] || Rukawa.config.log_file
        c.concurrency = options[:concurrency] if options[:concurrency]
      end
      load_job_definitions

      job_classes = job_name.map { |name| Object.const_get(name) }
      job_net_class = anonymous_job_net_class(*job_classes)
      job_net = job_net_class.new(nil)
      result = Runner.run(job_net, options[:batch], options[:refresh_interval])

      if options[:dot]
        job_net.output_dot(options[:dot])
      end

      exit 1 unless result
    end

    desc "list", "List JobNet"
    method_option :config, type: :string, default: nil, desc: "If this options is not set, try to load ./rukawa.rb"
    method_option :jobs, aliases: "-j", type: :boolean, desc: "Show jobs", default: false
    method_option :job_dirs, type: :array, default: [], desc: "Load job directories"
    def list
      load_config
      load_job_definitions
      Rukawa::Overview.list_job_net(with_jobs: options[:jobs])
    end

    desc "list_job", "List Job"
    method_option :config, type: :string, default: nil, desc: "If this options is not set, try to load ./rukawa.rb"
    method_option :job_dirs, type: :array, default: [], desc: "Load job directories"
    def list_job
      load_config
      load_job_definitions
      Rukawa::Overview.list_job
    end

    private

    def load_config
      if options[:config]
        load File.expand_path(options[:config], Dir.pwd)
      else
        load default_config_file if File.exists?(default_config_file)
      end
    end

    def default_config_file
      "./rukawa.rb"
    end

    def default_job_dirs
      [File.join(Dir.pwd, "job_nets"), File.join(Dir.pwd, "jobs")]
    end

    def load_job_definitions
      job_dirs = (default_job_dirs + options[:job_dirs]).map { |d| File.expand_path(d) }.uniq
      job_dirs.each do |dir|
        Dir.glob(File.join(dir, "**/*.rb")) { |f| load f }
      end
    end

    def anonymous_job_net_class(*job_classes)
      Class.new(JobNet) do
        self.singleton_class.send(:define_method, :dependencies) do
          job_classes.map { |klass| [klass, []] }.to_h
        end

        define_method(:name) { "AnonymousJobNet" }
      end
    end
  end
end
