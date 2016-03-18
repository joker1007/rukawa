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
end

class Job1 < SampleJob
end
class Job2 < SampleJob
end
class Job3 < SampleJob
end
class Job4 < SampleJob
end
class Job5 < SampleJob
  def run
    raise "job5 error"
  end
end
class Job6 < SampleJob
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
