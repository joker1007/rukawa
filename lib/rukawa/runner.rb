require 'terminal-table'
require 'paint'
require 'rukawa/overview'

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
        Overview.display_running_status(@root_job_net) unless batch_mode
        sleep refresh_interval
      end
      Rukawa.logger.info("=== Finish Rukawa ===")

      Overview.display_running_status(@root_job_net) unless batch_mode
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
  end
end
