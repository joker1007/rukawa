require 'active_job'

class ActiveJobSample1 < ActiveJob::Base
  queue_as :default

  def perform
    sleep 10
    p "active_job1"
  end
end

class ActiveJobSample2 < ActiveJob::Base
  queue_as :default

  def perform
    sleep 10
    raise "active_job2 is failed"
  end
end
