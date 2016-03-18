$LOAD_PATH.unshift File.expand_path('../../lib', __FILE__)
require 'rukawa'
require 'rukawa/runner'

Dir.glob(File.expand_path('../../sample/job_nets/**/*.rb', __FILE__)).each { |f| require f }
Dir.glob(File.expand_path('../../sample/jobs/**/*.rb', __FILE__)).each { |f| require f }
