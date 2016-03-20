class InnerJobNet < Rukawa::JobNet
  class << self
    def dependencies
      {
        InnerJob3 => [],
        InnerJob1 => [],
        InnerJob2 => [InnerJob1, InnerJob3],
      }
    end
  end
end

class InnerJobNet2 < Rukawa::JobNet
  class << self
    def dependencies
      {
        InnerJob4 => [],
        InnerJob5 => [],
        InnerJob6 => [InnerJob4, InnerJob5],
      }
    end
  end
end

class SampleJobNet < Rukawa::JobNet
  class << self
    def dependencies
      {
        Job1 => [],
        Job2 => [Job1], Job3 => [Job1],
        Job4 => [Job2, Job3],
        InnerJobNet => [Job3],
        Job8 => [InnerJobNet],
        Job5 => [Job3],
        Job6 => [Job4, Job5],
        Job7 => [Job6],
        InnerJobNet2 => [Job4],
      }
    end
  end
end
