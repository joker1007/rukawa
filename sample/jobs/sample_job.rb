class SampleJob < Rukawa::Job
  def run
    sleep rand(5)
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
