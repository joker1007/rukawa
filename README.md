# Rukawa
[![Gem Version](https://badge.fury.io/rb/rukawa.svg)](https://badge.fury.io/rb/rukawa)
[![Build Status](https://travis-ci.org/joker1007/rukawa.svg?branch=master)](https://travis-ci.org/joker1007/rukawa)
[![Code Climate](https://codeclimate.com/github/joker1007/rukawa/badges/gpa.svg)](https://codeclimate.com/github/joker1007/rukawa)

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

See [sample/jobs/sample_job.rb](https://github.com/joker1007/rukawa/blob/master/sample/jobs/sample_job.rb).

### JobNet Definition

See [sample/job_nets/sample_job_net.rb](https://github.com/joker1007/rukawa/blob/master/sample/job_nets/sample_job_net.rb).

### JobGraph
![jobnet.png](https://raw.githubusercontent.com/joker1007/rukawa/master/sample/jobnet.png)

### Execution

```
% cd rukawa/sample

# load ./jobs/**/*.rb, ./job_net/**/*.rb automatically
% bundle exec rukawa run SampleJobNet -r 1 -d result.dot
+--------------+---------+
| Job          | Status  |
+--------------+---------+
| Job1         | waiting |
| Job2         | waiting |
| Job3         | waiting |
| Job4         | waiting |
| InnerJobNet  | waiting |
|   InnerJob3  | waiting |
|   InnerJob1  | waiting |
|   InnerJob2  | waiting |
| Job8         | waiting |
| Job5         | waiting |
| Job6         | waiting |
| Job7         | waiting |
| InnerJobNet2 | waiting |
|   InnerJob4  | waiting |
|   InnerJob5  | waiting |
|   InnerJob6  | waiting |
+--------------+---------+
+--------------+----------+
| Job          | Status   |
+--------------+----------+
| Job1         | finished |
| Job2         | finished |
| Job3         | finished |
| Job4         | finished |
| InnerJobNet  | running  |
|   InnerJob3  | running  |
|   InnerJob1  | running  |
|   InnerJob2  | waiting  |
| Job8         | waiting  |
| Job5         | error    |
| Job6         | error    |
| Job7         | error    |
| InnerJobNet2 | running  |
|   InnerJob4  | running  |
|   InnerJob5  | skipped  |
|   InnerJob6  | waiting  |
+--------------+----------+
+--------------+----------+
| Job          | Status   |
+--------------+----------+
| Job1         | finished |
| Job2         | finished |
| Job3         | finished |
| Job4         | finished |
| InnerJobNet  | error    |
|   InnerJob3  | finished |
|   InnerJob1  | finished |
|   InnerJob2  | error    |
| Job8         | error    |
| Job5         | error    |
| Job6         | error    |
| Job7         | error    |
| InnerJobNet2 | finished |
|   InnerJob4  | finished |
|   InnerJob5  | skipped  |
|   InnerJob6  | skipped  |
+--------------+----------+

# generate result graph image
% dot -Tpng -o result.png result.dot
```

![jobnet.png](https://raw.githubusercontent.com/joker1007/rukawa/master/sample/result.png)

### Resume

Add `JOB_NAME` arguments to `run` command.

```
% bundle exec rukawa run SampleJobNet Job8 InnerJob4 -r 5 -c 10
+----------------+----------+
| Job            | Status   |
+----------------+----------+
| Job1           | bypassed |
| Job2           | bypassed |
| Job3           | bypassed |
| Job4           | bypassed |
| InnerJobNet    | bypassed |
|   InnerJob3    | bypassed |
|   InnerJob1    | bypassed |
|   InnerJob2    | bypassed |
| Job8           | waiting  |
| Job5           | bypassed |
| Job6           | bypassed |
| Job7           | bypassed |
| InnerJobNet2   | waiting  |
|   InnerJob4    | waiting  |
|   InnerJob5    | waiting  |
|   InnerJob6    | waiting  |
| InnerJobNet3   | waiting  |
|   InnerJob7    | waiting  |
|   InnerJob8    | waiting  |
|   InnerJob9    | waiting  |
|   InnerJob10   | waiting  |
| InnerJobNet4   | waiting  |
|   InnerJob11   | waiting  |
|   InnerJob12   | waiting  |
|   InnerJob13   | waiting  |
|   NestedJobNet | waiting  |
|     NestedJob1 | waiting  |
|     NestedJob2 | waiting  |
+----------------+----------+
+----------------+----------+
| Job            | Status   |
+----------------+----------+
| Job1           | bypassed |
| Job2           | bypassed |
| Job3           | bypassed |
| Job4           | bypassed |
| InnerJobNet    | bypassed |
|   InnerJob3    | bypassed |
|   InnerJob1    | bypassed |
|   InnerJob2    | bypassed |
| Job8           | finished |
| Job5           | bypassed |
| Job6           | bypassed |
| Job7           | bypassed |
| InnerJobNet2   | skipped  |
|   InnerJob4    | finished |
|   InnerJob5    | skipped  |
|   InnerJob6    | skipped  |
| InnerJobNet3   | running  |
|   InnerJob7    | finished |
|   InnerJob8    | running  |
|   InnerJob9    | waiting  |
|   InnerJob10   | waiting  |
| InnerJobNet4   | waiting  |
|   InnerJob11   | waiting  |
|   InnerJob12   | waiting  |
|   InnerJob13   | waiting  |
|   NestedJobNet | waiting  |
|     NestedJob1 | waiting  |
|     NestedJob2 | waiting  |
+----------------+----------+
```

In above case, All jobs except `Job8` and `InnerJob4` and depending them are set `bypassed`.
`bypassed` means that job is not executed, and regarded as successful.
For example, a job depends two other jobs. Even if either job is `bypassed`, and another job is `finished`, it is executed.


### Run Specific jobs

`run_job` command executes specified job forcely.

```
% be rukawa run_job Job8 InnerJob6 NestedJob1 -c 3 -r 5
+------------+---------+
| Job        | Status  |
+------------+---------+
| Job8       | waiting |
| InnerJob6  | waiting |
| NestedJob1 | running |
+------------+---------+
+------------+----------+
| Job        | Status   |
+------------+----------+
| Job8       | finished |
| InnerJob6  | finished |
| NestedJob1 | finished |
+------------+----------+
```

Main usage is manual reentering.

### Output jobnet graph (dot file)

```
% bundle exec rukawa graph -o SampleJobNet.dot SampleJobNet
% dot -Tpng -o SampleJobNet.png SampleJobNet.dot
```

### help
```
% bundle exec rukawa help run
Usage:
  rukawa run JOB_NET_NAME [JOB_NAME] [JOB_NAME] ...

Options:
  -c, [--concurrency=N]           # Default: cpu count
      [--variables=key:value]
      [--config=CONFIG]           # If this options is not set, try to load ./rukawa.rb
      [--job-dirs=one two three]  # Load job directories
  -b, [--batch], [--no-batch]     # If batch mode, not display running status
  -l, [--log=LOG]
                                  # Default: ./rukawa.log
      [--stdout], [--no-stdout]   # Output log to stdout
  -d, [--dot=DOT]                 # Output job status by dot format
  -r, [--refresh-interval=N]      # Refresh interval for running status information
                                  # Default: 3

Run jobnet. If JOB_NET is set, resume from JOB_NAME


% bundle exec rukawa help run_job
Usage:
  rukawa run_job JOB_NAME [JOB_NAME] ...

Options:
  -c, [--concurrency=N]           # Default: cpu count
      [--variables=key:value]
      [--config=CONFIG]           # If this options is not set, try to load ./rukawa.rb
      [--job-dirs=one two three]  # Load job directories
  -b, [--batch], [--no-batch]     # If batch mode, not display running status
  -l, [--log=LOG]
                                  # Default: ./rukawa.log
      [--stdout], [--no-stdout]   # Output log to stdout
  -d, [--dot=DOT]                 # Output job status by dot format
  -r, [--refresh-interval=N]      # Refresh interval for running status information
                                  # Default: 3

Run specific jobs.

% bundle exec rukawa help graph
Usage:
  rukawa graph JOB_NET_NAME [JOB_NAME] [JOB_NAME] ... -o, --output=OUTPUT

Options:
      [--config=CONFIG]           # If this options is not set, try to load ./rukawa.rb
      [--job-dirs=one two three]
  -o, --output=OUTPUT

Output jobnet graph. If JOB_NET is set, simulate resumed job sequence
```

## ToDo
- Write more tests
- Enable use variables

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment. Run `bundle exec rukawa` to use the gem in this directory, ignoring other installed copies of this gem.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/joker1007/rukawa.

