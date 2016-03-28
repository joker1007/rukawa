require 'spec_helper'

describe Rukawa do
  it 'run jobs correctly' do
    Rukawa.configure do |c|
      c.log_file = STDOUT
    end
    Rukawa::Runner.run(SampleJobNet.new(nil), true)
    expect(ExecuteLog.store).to match({
      Job1 => an_instance_of(Time),
      Job3 => an_instance_of(Time),
      Job4 => an_instance_of(Time),
      Job6 => an_instance_of(Time),
      Job7 => an_instance_of(Time),
      InnerJob3 => an_instance_of(Time),
      InnerJob1 => an_instance_of(Time),
      InnerJob4 => an_instance_of(Time),
    })

    expect(ExecuteLog.store[Job3]).to satisfy { |v| v > ExecuteLog.store[Job1] }
    expect(ExecuteLog.store[Job4]).to satisfy { |v| v > ExecuteLog.store[Job3] }
    expect(ExecuteLog.store[Job6]).to satisfy { |v| v > ExecuteLog.store[Job4] }
    expect(ExecuteLog.store[Job7]).to satisfy { |v| v > ExecuteLog.store[Job6] }
    expect(ExecuteLog.store[InnerJob3]).to satisfy { |v| v > ExecuteLog.store[Job3] }
    expect(ExecuteLog.store[InnerJob1]).to satisfy { |v| v > ExecuteLog.store[Job3] }
    expect(ExecuteLog.store[InnerJob4]).to satisfy { |v| v > ExecuteLog.store[Job4] }
  end

  def find_job(job_net, job_class)
    job_net.dag.jobs.find { |n| n.is_a?(job_class) }.tap do |j|
      raise "Notfound" unless j
    end
  end

  it 'constructs dag correctly' do
    job_net = SampleJobNet.new(nil)
    job_classes = Set.new
    collect_jobs = ->(j, set) {
      j.dependencies.each_key do |n|
        if n.respond_to?(:dependencies)
          collect_jobs.call(n, set)
        else
          set << n
        end
      end
    }
    collect_jobs.call(SampleJobNet, job_classes)

    assert { job_net.dag.jobs.size == job_classes.size}

    job4 = find_job(job_net, Job4)
    expect(job4.in_comings.map(&:from)).to match_array([an_instance_of(Job2), an_instance_of(Job3)])

    job8 = find_job(job_net, Job8)
    expect(job8.in_comings.map(&:from)).to match_array([an_instance_of(InnerJob2)])
    expect(job8.out_goings.map(&:to)).to match_array([an_instance_of(InnerJob7), an_instance_of(InnerJob8)])

    inner_job11 = find_job(job_net, InnerJob11)
    expect(inner_job11.in_comings.map(&:from)).to match_array([an_instance_of(InnerJob9), an_instance_of(InnerJob10)])
    expect(inner_job11.out_goings.map(&:to)).to match_array([an_instance_of(NestedJob1)])

    inner_job12 = find_job(job_net, InnerJob12)
    expect(inner_job12.in_comings.map(&:from)).to match_array([an_instance_of(InnerJob9), an_instance_of(InnerJob10)])
    expect(inner_job12.out_goings.map(&:to)).to match_array([an_instance_of(NestedJob1)])
  end

  it 'skip hierarchy' do
    subclass = Class.new(InnerJobNet4) do
      add_skip_rule ->(job_net) { true }
    end
    job_net = subclass.new(nil)

    expect(job_net).to be_skip
    expect(job_net.dag.jobs).to all(be_skip)
  end
end
