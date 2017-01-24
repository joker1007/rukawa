require 'rukawa/builtins/base'
require 'active_support/core_ext/class'
require 'open3'

module Rukawa
  module Builtins
    class Shell < Base
      class_attribute :command, :args, :env, :chdir, :stdout, :stderr

      self.args = []
      self.stdout = $stdout
      self.stderr = $stderr

      class << self
        def handle_parameters(command:, args: [], env: nil, chdir: nil, stdout: nil, stderr: nil, **rest)
          self.command = command
          self.args = args
          self.env = env if env
          self.chdir = chdir if chdir
          self.stdout = stdout if stdout
          self.stderr = stderr if stderr
        end
      end

      def run
        cmdenv = env || {}
        opts = chdir ? {chdir: chdir} : {}

        if defined?(Bundler)
          result, log = nil
          Bundler.with_clean_env do
            result, log = execute_command([command, *args], cmdenv, opts)
          end
        else
          result, log = execute_command([command, *args], cmdenv, opts)
        end

        unless result.success?
          raise "command error"
        end
      end

      def execute_command(command, env, opts)
        log = "".dup
        result = Open3.popen3(env, *command, opts) do |stdin, out, err, wait_th|
          stdin.close
          until out.eof? && err.eof?
            rs, = IO.select([out, err])
            rs.each do |rio|
              line = rio.gets
              if line
                log << line
                if rio == out
                  stdout.write(line)
                else
                  stderr.write(line)
                end
              end
            end
          end

          wait_th.value
        end

        stdout.flush
        stderr.flush unless stdout == stderr

        return result, log
      end
    end
  end
end
