require 'spec_helper'

describe Rukawa::AbstractJob do
  describe ".add_skip_rule" do
    it "inheritable" do
      job_class1 = Class.new(Rukawa::AbstractJob) do
        add_skip_rule -> { true }
      end

      job_class2 = Class.new(job_class1)

      expect(job_class2.skip_rules.size).to eq(1)
    end

    it "changeable independent parent class" do
      job_class1 = Class.new(Rukawa::AbstractJob) do
        add_skip_rule -> { true }
      end

      job_class2 = Class.new(job_class1) do
        add_skip_rule -> { true }
      end

      expect(job_class1.skip_rules.size).to eq(1)
      expect(job_class2.skip_rules.size).to eq(2)
    end
  end

  describe "#formatted_elapsed_time_from" do
    using RSpec::Parameterized::TableSyntax
    where(:finished_at_time, :started_at_time, :result) do
      i = 1460286755
      Time.at(i) | Time.at(i - 30) | "30s"
      Time.at(i) | Time.at(i - 60) | "1m 0s"
      Time.at(i) | Time.at(i - 3600) | "1h 0m 0s"
      Time.at(i) | Time.at(i - 3620) | "1h 0m 20s"
      Time.at(i) | Time.at(i - 3680) | "1h 1m 20s"
    end

    with_them do
      it do
        _finished_at_time = finished_at_time
        _started_at_time = started_at_time
        job_class1 = Class.new(Rukawa::AbstractJob) do
          define_method(:finished_at) do
            _finished_at_time
          end

          define_method(:started_at) do
            _started_at_time
          end
        end

        job = job_class1.new
        assert do
          job.formatted_elapsed_time_from == result
        end
      end
    end
  end
end
