require 'spec_helper'

describe Rukawa::Dependency do
  describe "AllSuccess" do
    describe "#resolve" do
      using RSpec::Parameterized::TableSyntax

      where(:result1, :result2, :result3, :resolved) do
        Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | true
        Rukawa::State.get(:finished) | Rukawa::State.get(:bypassed) | Rukawa::State.get(:finished) | true
        Rukawa::State.get(:finished) | Rukawa::State.get(:skipped)  | Rukawa::State.get(:finished) | false
        nil                          | Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | false
      end

      with_them do
        subject { Rukawa::Dependency::AllSuccess.new(result1, result2, result3).resolve }
        it { is_expected.to eq(resolved) }
      end
    end
  end

  describe "AllDone" do
    describe "#resolve" do
      using RSpec::Parameterized::TableSyntax

      where(:result1, :result2, :result3, :resolved) do
        Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | true
        Rukawa::State.get(:finished) | Rukawa::State.get(:bypassed) | Rukawa::State.get(:finished) | true
        Rukawa::State.get(:finished) | Rukawa::State.get(:skipped)  | Rukawa::State.get(:finished) | true
        nil                          | Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | true
      end

      with_them do
        subject { Rukawa::Dependency::AllDone.new(result1, result2, result3).resolve }
        it { is_expected.to eq(resolved) }
      end
    end
  end

  describe "OneSuccess" do
    describe "#resolve" do
      using RSpec::Parameterized::TableSyntax

      where(:result1, :result2, :result3, :resolved) do
        Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | true
        Rukawa::State.get(:finished) | Rukawa::State.get(:skipped)  | Rukawa::State.get(:finished) | true
        nil                          | Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | true
        nil                          | nil                          | Rukawa::State.get(:finished) | true
        nil                          | nil                          | Rukawa::State.get(:skipped)  | false
        nil                          | nil                          | nil                          | false
        Rukawa::State.get(:skipped)  | Rukawa::State.get(:skipped)  | Rukawa::State.get(:skipped)  | false
        nil                          | nil                          | Rukawa::State.get(:bypassed) | true
      end

      with_them do
        subject { Rukawa::Dependency::OneSuccess.new(result1, result2, result3).resolve }
        it { is_expected.to eq(resolved) }
      end
    end
  end

  describe "AllSuccessOrSkipped" do
    describe "#resolve" do
      using RSpec::Parameterized::TableSyntax

      where(:result1, :result2, :result3, :resolved) do
        Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | true
        Rukawa::State.get(:finished) | Rukawa::State.get(:skipped)  | Rukawa::State.get(:finished) | true
        nil                          | Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | false
        Rukawa::State.get(:skipped)  | Rukawa::State.get(:skipped)  | Rukawa::State.get(:skipped)  | true
        Rukawa::State.get(:bypassed) | Rukawa::State.get(:skipped)  | Rukawa::State.get(:skipped)  | true
      end

      with_them do
        subject { Rukawa::Dependency::AllSuccessOrSkipped.new(result1, result2, result3).resolve }
        it { is_expected.to eq(resolved) }
      end
    end
  end

  describe "OneSuccessOrSkipped" do
    describe "#resolve" do
      using RSpec::Parameterized::TableSyntax

      where(:result1, :result2, :result3, :resolved) do
        Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | true
        Rukawa::State.get(:finished) | Rukawa::State.get(:skipped)  | Rukawa::State.get(:finished) | true
        nil                          | Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | true
        nil                          | nil                          | Rukawa::State.get(:finished) | true
        nil                          | nil                          | nil                          | false
        Rukawa::State.get(:skipped)  | Rukawa::State.get(:skipped)  | Rukawa::State.get(:skipped)  | true
        nil                          | Rukawa::State.get(:skipped)  | Rukawa::State.get(:skipped)  | true
        nil                          | nil                          | Rukawa::State.get(:skipped)  | true
        nil                          | nil                          | Rukawa::State.get(:bypassed) | true
      end

      with_them do
        subject { Rukawa::Dependency::OneSuccessOrSkipped.new(result1, result2, result3).resolve }
        it { is_expected.to eq(resolved) }
      end
    end
  end

  describe "AllFailed" do
    describe "#resolve" do
      using RSpec::Parameterized::TableSyntax

      where(:result1, :result2, :result3, :resolved) do
        Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | false
        Rukawa::State.get(:finished) | Rukawa::State.get(:skipped)  | Rukawa::State.get(:finished) | false
        nil                          | Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | false
        nil                          | nil                          | Rukawa::State.get(:finished) | false
        nil                          | nil                          | nil                          | true
        Rukawa::State.get(:skipped)  | Rukawa::State.get(:skipped)  | Rukawa::State.get(:skipped)  | false
        nil                          | Rukawa::State.get(:skipped)  | Rukawa::State.get(:skipped)  | false
        nil                          | nil                          | Rukawa::State.get(:skipped)  | false
        nil                          | nil                          | Rukawa::State.get(:bypassed) | false
      end

      with_them do
        subject { Rukawa::Dependency::AllFailed.new(result1, result2, result3).resolve }
        it { is_expected.to eq(resolved) }
      end
    end
  end

  describe "OneFailed" do
    describe "#resolve" do
      using RSpec::Parameterized::TableSyntax

      where(:result1, :result2, :result3, :resolved) do
        Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | false
        Rukawa::State.get(:finished) | Rukawa::State.get(:skipped)  | Rukawa::State.get(:finished) | false
        nil                          | Rukawa::State.get(:finished) | Rukawa::State.get(:finished) | true
        nil                          | nil                          | Rukawa::State.get(:finished) | true
        nil                          | nil                          | nil                          | true
        Rukawa::State.get(:skipped)  | Rukawa::State.get(:skipped)  | Rukawa::State.get(:skipped)  | false
        nil                          | Rukawa::State.get(:skipped)  | Rukawa::State.get(:skipped)  | true
        nil                          | nil                          | Rukawa::State.get(:skipped)  | true
        nil                          | nil                          | Rukawa::State.get(:bypassed) | true
      end

      with_them do
        subject { Rukawa::Dependency::OneFailed.new(result1, result2, result3).resolve }
        it { is_expected.to eq(resolved) }
      end
    end
  end
end
