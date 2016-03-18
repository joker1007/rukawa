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

class SampleJobNet < Rukawa::JobNet
  class << self
    # +------------+
    # |    job1    |
    # |            |
    # +------+-----+
    #        |
    #        +-----------------+
    #        |                 |
    #        |                 |
    # +------v-----+    +------v-----+
    # |    job2    |    |    job3    |
    # |            |    |            |
    # +------+-----+    +-----+--+---+
    #        |                |  |
    #        <----------------+  |
    #        |                   |
    #        |                   |
    # +------v-----+      +------v-----+
    # |    job4    |      |    job5    |
    # |            |      |            |
    # +------+-----+      +------+-----+
    #        |                   |
    #        |                   |
    #        <-------------------+
    #        |
    # +------v-----+
    # |    job6    |
    # |            |
    # +------+-----+
    #        |
    #        |
    #        |
    #        |
    # +------v-----+
    # |    job7    |
    # |            |
    # +------------+
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
      }
    end
  end
end
