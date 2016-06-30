require 'thor'
require 'rukawa/runner'
require 'rukawa/overview'

module Rukawa
  class Cli < Thor

    def self.base_options
      method_option :config, type: :string, default: nil, desc: "If this options is not set, try to load ./rukawa.rb"
      method_option :job_dirs, type: :array, default: [], desc: "Load job directories", banner: "JOB_DIR1 JOB_DIR2"
    end

    def self.run_options
      method_option :concurrency, aliases: "-c", type: :numeric, default: nil, desc: "Default: cpu count"
      method_option :variables, aliases: "--var", type: :hash, default: {}, banner: "KEY:VALUE KEY:VALUE"
      method_option :varfile, type: :string, default: nil, desc: "variable definition file. ex (variables.yml, variables.json)"
      method_option :batch, aliases: "-b", type: :boolean, default: false, desc: "If batch mode, not display running status"
      method_option :log, aliases: "-l", type: :string, desc: "Default: ./rukawa.log"
      method_option :stdout, type: :boolean, default: false, desc: "Output log to stdout"
      method_option :syslog, type: :boolean, default: false, desc: "Output log to syslog"
      method_option :dot, aliases: "-d", type: :string, default: nil, desc: "Output job status by dot format"
      method_option :format, aliases: "-f", type: :string, desc: "Output job status format: png, svg, pdf, ... etc"
      method_option :refresh_interval, aliases: "-r", type: :numeric, default: 3, desc: "Refresh interval for running status information"
    end

    desc "run JOB_NET_NAME [JOB_NAME] [JOB_NAME] ...", "Run jobnet. If JOB_NET is set, resume from JOB_NAME"
    map "run" => "_run"
    base_options
    run_options
    def _run(job_net_name, *job_name)
      load_config
      set_logger
      set_concurrency
      load_job_definitions

      job_net_class = get_class(job_net_name)
      job_classes = job_name.map { |name| get_class(name) }
      job_net = job_net_class.new(nil, variables, Context.new, *job_classes)
      result = Runner.run(job_net, options[:batch], options[:refresh_interval])

      if options[:dot]
        job_net.output_dot(options[:dot], format: options[:format])
      end

      unless result
        puts "\nIf you want to retry, run following command."
        failed_jobs = job_net.dag.jobs.each_with_object([]) { |j, arr| arr << j.class.to_s if j.state == Rukawa::State::Error }
        puts "  rukawa run #{job_net_name} #{failed_jobs.join(" ")}"
        exit 1
      end
    end

    desc "graph JOB_NET_NAME [JOB_NAME] [JOB_NAME] ...", "Output jobnet graph. If JOB_NET is set, simulate resumed job sequence"
    base_options
    method_option :output, aliases: "-o", type: :string, required: true
    method_option :format, aliases: "-f", type: :string
    def graph(job_net_name, *job_name)
      load_config
      load_job_definitions

      job_net_class = get_class(job_net_name)
      job_classes = job_name.map { |name| get_class(name) }
      job_net = job_net_class.new(nil, {}, Context.new, *job_classes)
      job_net.output_dot(options[:output], format: options[:format])
    end

    desc "run_job JOB_NAME [JOB_NAME] ...", "Run specific jobs."
    base_options
    run_options
    def run_job(*job_name)
      load_config
      set_logger
      set_concurrency
      load_job_definitions

      job_classes = job_name.map { |name| get_class(name) }
      job_net_class = anonymous_job_net_class(*job_classes)
      job_net = job_net_class.new(nil, variables, Context.new)
      result = Runner.run(job_net, options[:batch], options[:refresh_interval])

      if options[:dot]
        job_net.output_dot(options[:dot])
      end

      exit 1 unless result
    end

    desc "list", "List JobNet"
    base_options
    method_option :jobs, aliases: "-j", type: :boolean, desc: "Show jobs", default: false
    def list
      load_config
      load_job_definitions
      Rukawa::Overview.list_job_net(with_jobs: options[:jobs])
    end

    desc "list_job", "List Job"
    base_options
    def list_job
      load_config
      load_job_definitions
      Rukawa::Overview.list_job
    end

    map %w[version -v] => "__print_version"
    desc "version(-v)", "Print the version"
    def __print_version
      puts "rukawa #{Rukawa::VERSION}"
    end

    private

    def load_config
      if options[:config]
        load File.expand_path(options[:config], Dir.pwd)
      else
        load default_config_file if File.exists?(default_config_file)
      end

      Rukawa.configure do |c|
        c.job_dirs.concat(options[:job_dirs]) unless options[:job_dirs].empty?
      end
    end

    def set_logger
      Rukawa.configure do |c|
        if options[:stdout]
          c.logger = Logger.new($stdout)
        elsif options[:syslog]
          require 'syslog/logger'
          c.logger = Syslog::Logger.new('rukawa')
        elsif options[:log]
          c.logger = Logger.new(options[:log])
        else
          c.logger ||= Logger.new('./rukawa.log');
        end
      end
    end

    def set_concurrency
      Rukawa.configure do |c|
        c.concurrency = options[:concurrency] if options[:concurrency]
      end
    end

    def default_config_file
      "./rukawa.rb"
    end

    def load_job_definitions
      Rukawa.load_jobs
    end

    def get_class(name)
      Object.const_get(name)
    rescue NameError
      $stderr.puts("`#{name}` class is not found")
      exit 1
    end

    def anonymous_job_net_class(*job_classes)
      Class.new(JobNet) do
        self.singleton_class.send(:define_method, :dependencies) do
          job_classes.map { |klass| [klass, []] }.to_h
        end

        define_method(:name) { "AnonymousJobNet" }
      end
    end

    def variables
      if options[:varfile]
        read_varfile.freeze
      else
        options[:variables].freeze
      end
    end

    def read_varfile
      unless File.exist?(options[:varfile])
        $stderr.puts("`#{options[:varfile]}` is not found")
        exit 1
      end

      extname = File.extname(options[:varfile])
      if %w(.yml .yaml).include?(extname)
        require 'yaml'
        deserializer = ->(data) { YAML.load(data) }
      elsif %w(.js .json).include?(extname)
        require 'json'
        deserializer = ->(data) { JSON.load(data) }
      end

      deserializer.call(File.read(options[:varfile]))
    end
  end
end
