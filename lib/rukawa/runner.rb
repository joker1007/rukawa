require 'terminal-table'
require 'paint'

module Rukawa
  class Runner
    REFRESH_INTERVAL = 5

    def self.run(job_net, batch_mode = false)
      new.run(job_net, batch_mode)
    end

    def run(job_net, batch_mode = false)
      @job_net = job_net

      Rukawa.logger.info("=== Start #{@job_net.class} ===")
      futures = @job_net.run
      until futures.all?(&:complete?)
        display_table unless batch_mode
        sleep REFRESH_INTERVAL
      end
      Rukawa.logger.info("=== Finish #{@job_net.class} ===")

      display_table unless batch_mode

      has_error = false
      @job_net.dag.each do |j|
        if j.dataflow.reason
          has_error = true
          Rukawa.logger.error(j.dataflow.reason)
        end
      end

      if has_error
        exit 1
      end
    end

    private

    def display_table
      table = Terminal::Table.new headings: ["Job", "Status"] do |t|
        @job_net.dag.each do |j|
          t << [Paint[j.class.to_s, :bold], colored_state(j.state)]
        end
      end
      puts table
    end

    def colored_state(state)
      case state
      when :finished
        Paint[state.to_s, :green]
      when :error
        Paint[state.to_s, :red]
      when :running
        Paint[state.to_s, :blue]
      when :waiting
        Paint[state.to_s, :yellow]
      else
        state.to_s
      end
    end
  end
end
