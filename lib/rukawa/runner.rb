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
    end

    def run(batch_mode = false, refresh_interval = DEFAULT_REFRESH_INTERVAL)
      displayed_at = Time.at(0)
      promise = @root_job_net.run do
        unless batch_mode
          if Time.now - displayed_at >= refresh_interval
            displayed_at = Time.now
            Overview.display_running_status(@root_job_net)
          end
        end
      end
      futures = promise.value

      Overview.display_running_status(@root_job_net) unless batch_mode
      puts "Finished #{@root_job_net.name} in #{@root_job_net.formatted_elapsed_time_from}"

      if futures.all?(&:fulfilled?)
        true
      else
        false
      end
    end
  end
end
