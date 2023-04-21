$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rukawa'
require 'rukawa/runner'
require 'rspec-power_assert'
require 'rspec-parameterized'
require 'active_job'

RSpec::PowerAssert.example_assertion_alias :assert

Dir.glob(File.expand_path('../../sample/job_nets/**/*.rb', __FILE__)).each { |f| require f }
Dir.glob(File.expand_path('../../sample/jobs/**/*.rb', __FILE__)).each { |f| require f }

redis_host = ENV["REDIS_HOST"] || "localhost:6379"
Rukawa.configure do |c|
  c.status_store = ActiveSupport::Cache::RedisCacheStore.new(url: "redis://#{redis_host}")
end

Rukawa.config.status_store.write("rukawa.test", "test", expires_in: 60)
unless Rukawa.config.status_store.fetch("rukawa.test") == "test"
  raise "status_store is bad"
end

ActiveJob::Base.queue_adapter = :sucker_punch
