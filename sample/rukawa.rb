Rukawa.configure do |c|
  c.graph.concentrate = true
  c.graph.nodesep = 0.8
end

redis_host = ENV["REDIS_HOST"] || "localhost:6379"
Rukawa.configure do |c|
  c.status_store = ActiveSupport::Cache::RedisStore.new(redis_host)
end

require 'active_job'
ActiveJob::Base.queue_adapter = :sucker_punch
