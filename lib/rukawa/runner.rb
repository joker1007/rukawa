require 'terminal-table'
require 'paint'

module Rukawa
  class Runner
    DEFAULT_REFRESH_INTERVAL = 3

    def self.run(job_net, batch_mode = false, refresh_interval = DEFAULT_REFRESH_INTERVAL)
      new(job_net).run(batch_mode, refresh_interval)
    end

    def initialize(root_job_net)
      @root_job_net = root_job_net
      @errors = []
    end

    def run(batch_mode = false, refresh_interval = DEFAULT_REFRESH_INTERVAL)
      Rukawa.logger.info("=== Start Rukawa ===")
      futures = @root_job_net.dataflows.each(&:execute)
      until futures.all?(&:complete?)
        display_table unless batch_mode
        sleep refresh_interval
      end
      Rukawa.logger.info("=== Finish Rukawa ===")

      display_table unless batch_mode
      puts "Finished #{@root_job_net.name} in #{@root_job_net.formatted_elapsed_time_from}"

      errors = futures.map(&:reason).compact

      unless errors.empty?
        errors.each do |err|
          next if err.is_a?(DependencyUnsatisfied)
          Rukawa.logger.error(err)
        end
        return false
      end

      true
    end

    private

    def display_table
      table = Terminal::Table.new headings: ["Job", "Status", "Elapsed Time"] do |t|
        @root_job_net.each_with_index do |j|
          table_row(t, j)
        end
      end
      puts table
    end

    def table_row(table, job, level = 0)
      if job.is_a?(JobNet)
        table << [Paint["#{"  " * level}#{job.class}", :bold, :underline], Paint[job.state.colored, :bold, :underline], Paint[job.formatted_elapsed_time_from, :bold, :underline]]
        job.each do |inner_j|
          table_row(table, inner_j, level + 1)
        end
      else
        table << [Paint["#{"  " * level}#{job.class}", :bold], job.state.colored, job.formatted_elapsed_time_from]
      end
    end
  end
end
