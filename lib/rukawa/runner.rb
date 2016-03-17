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

      futures = @job_net.run
      until futures.all?(&:complete?)
        display_table unless batch_mode
        sleep REFRESH_INTERVAL
      end

      display_table unless batch_mode

      has_error = false
      futures.each do |f|
        if f.reason
          has_error = true
          Rukawa.logger.error(f.reason)
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
      when :fulfilled
        Paint[state.to_s, :green]
      when :rejected
        Paint[state.to_s, :red]
      when :processing
        Paint[state.to_s, :blue]
      when :pending
        Paint[state.to_s, :yellow]
      when :unscheduled
        state.to_s
      end
    end
  end
end
