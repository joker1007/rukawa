module ExecuteLog
  def self.store
    @store ||= {}
  end
end

class SampleJob < Rukawa::Job
  def run
    sleep rand(5)
    ExecuteLog.store[self.class] = Time.now
  end

  def ext_method
    puts "ext target"
  end
end

class Job1 < SampleJob
  set_description "Job1 description body"

  def run
    p variables unless variables.empty?
    ext_method
    super
  end
end
class Job2 < SampleJob
  def run
    raise "job2 error"
  end
end
class Job3 < SampleJob
end
class Job4 < SampleJob
  # inherited by subclass
  set_dependency_type :one_success
  set_resource_count 3
end
class Job5 < SampleJob
  # inherited by subclass
  set_retryable limit: 3, wait: 2, type: RuntimeError

  def run
    raise "job5 error"
  end
end
class Job6 < SampleJob
  set_dependency_type :one_failed
end
class Job7 < SampleJob
end
class Job8 < SampleJob
end

class InnerJob1 < SampleJob
end

class InnerJob2 < SampleJob
  def run
    raise "inner job2 error"
  end
end

class InnerJob3 < SampleJob
end

class InnerJob4 < SampleJob
end

class InnerJob5 < SampleJob
  # inherited by subclass
  add_skip_rule ->(job) { job.is_a?(SampleJob) }
end

class InnerJob6 < SampleJob
end

class InnerJob7 < SampleJob
end

class InnerJob8 < SampleJob
end

class InnerJob9 < SampleJob
end

class InnerJob10 < SampleJob
end

class InnerJob11 < SampleJob
end

class InnerJob12 < SampleJob
end

class InnerJob13 < SampleJob
end

class NestedJob1 < SampleJob
end

class NestedJob2 < SampleJob
end
