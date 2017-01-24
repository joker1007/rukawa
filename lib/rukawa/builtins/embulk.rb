require 'rukawa/builtins/shell'

module Rukawa
  module Builtins
    class Embulk < Shell
      class_attribute :config, :embulk_bin, :embulk_bundle, :embulk_vm_options, :jvm_options

      self.embulk_bin = "embulk"
      self.embulk_bundle = nil
      self.embulk_vm_options = []
      self.jvm_options = []

      class << self
        def def_parameters(config:, embulk_bin: nil, embulk_bundle: nil, embulk_vm_options: nil, jvm_options: nil, stdout: nil, stderr: nil, env: nil, chdir: nil)
          self.config = config
          self.embulk_bin = embulk_bin if embulk_bin
          self.embulk_bundle = embulk_bundle if embulk_bundle
          self.embulk_vm_options = embulk_vm_options if embulk_vm_options
          self.jvm_options = jvm_options if jvm_options
          self.stdout = stdout if stdout
          self.stderr = stderr if stderr
          self.env = env if env
          self.chdir = chdir if chdir
        end
      end

      def run
        process = -> do
          if ENV["EMBULK_DRY_RUN"]
            stdout.puts File.read(config)
            cmds = [embulk_bin, "preview", *embulk_bundle, config].compact
            stdout.puts cmds.join(" ")
          else
            cmds = [embulk_bin, *embulk_vm_options, *jvm_options, "run", *embulk_bundle, config].compact
            stdout.puts cmds.join(" ")
          end

          stdout.flush

          cmdenv = env || {}
          opts = chdir ? {chdir: chdir} : {}
          result, log = execute_command(cmds, cmdenv, opts)

          unless result.success?
            next if log =~ /NoSampleException/
            raise "embulk error"
          end
        end

        if defined?(Bundler)
          Bundler.with_clean_env(&process)
        else
          process.call
        end
      end
    end
  end
end
