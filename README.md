# Rukawa
Rukawa = (流川)

This gem is workflow engine and this is hyper simple.
Job is defined by Ruby class.
Dependency of each jobs is defined by Hash.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'rukawa'
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install rukawa

## Usage

### Job Definition

```rb
# jobs/sample_job.rb

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
```

### JobNet Definition
```rb
# job_nets/sample_job_net.rb
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
        Job5 => [Job3],
        Job6 => [Job4, Job5],
        Job7 => [Job6],
      }
    end
  end
end
```

```
% cd rukawa/sample
% bundle exec rukawa run SampleJobNet
+------+-------------+
| Job  | Status      |
+------+-------------+
| Job1 | pending     |
| Job2 | unscheduled |
| Job3 | unscheduled |
| Job4 | unscheduled |
| Job5 | unscheduled |
| Job6 | unscheduled |
| Job7 | pending     |
+------+-------------+
+------+-------------+
| Job  | Status      |
+------+-------------+
| Job1 | fulfilled   |
| Job2 | fulfilled   |
| Job3 | fulfilled   |
| Job4 | processing  |
| Job5 | rejected    |
| Job6 | unscheduled |
| Job7 | processing  |
+------+-------------+
+------+-----------+
| Job  | Status    |
+------+-----------+
| Job1 | fulfilled |
| Job2 | fulfilled |
| Job3 | fulfilled |
| Job4 | fulfilled |
| Job5 | rejected  |
| Job6 | rejected  |
| Job7 | rejected  |
+------+-----------+
```

## ToDo
- Write tests
- Enable use variables
- Output graphviz

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec rukawa` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/joker1007/rukawa.

