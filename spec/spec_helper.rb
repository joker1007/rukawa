$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rukawa'
require 'rukawa/runner'
require 'rspec-power_assert'
require 'rspec-parameterized'
require 'redis-activesupport'
require 'active_job'

RSpec::PowerAssert.example_assertion_alias :assert

Dir.glob(File.expand_path('../../sample/job_nets/**/*.rb', __FILE__)).each { |f| require f }
Dir.glob(File.expand_path('../../sample/jobs/**/*.rb', __FILE__)).each { |f| require f }

redis_host = ENV["REDIS_HOST"] || "localhost:6379"
Rukawa.configure do |c|
  c.status_store = ActiveSupport::Cache::RedisStore.new(redis_host)
end

ActiveJob::Base.queue_adapter = :sucker_punch
