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
end
