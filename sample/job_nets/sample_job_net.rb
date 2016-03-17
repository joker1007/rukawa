class SampleJobNet < Rukawa::JobNet
  class << self
    def dependencies
      {
        Job1 => [],
        Job2 => [Job1], Job3 => [Job1],
        Job4 => [Job2, Job3],
        Job5 => [Job3],
        Job6 => [Job4, Job5],
        Job7 => [Job6],
      }
    end
  end
end
