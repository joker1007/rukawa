require 'spec_helper'

describe Rukawa do
  it 'run jobs correctly' do
    Rukawa.configure do |c|
      c.log_file = STDOUT
    end
    Rukawa::Runner.run(SampleJobNet.new, true)
    expect(ExecuteLog.store).to match({
      Job1 => an_instance_of(Time),
      Job2 => an_instance_of(Time),
      Job3 => an_instance_of(Time),
      Job4 => an_instance_of(Time),
      InnerJob3 => an_instance_of(Time),
      InnerJob1 => an_instance_of(Time),
      InnerJob4 => an_instance_of(Time),
    })

    expect(ExecuteLog.store[Job2]).to satisfy { |v| v > ExecuteLog.store[Job1] }
    expect(ExecuteLog.store[Job3]).to satisfy { |v| v > ExecuteLog.store[Job1] }
    expect(ExecuteLog.store[Job4]).to satisfy { |v| v > ExecuteLog.store[Job2] }
    expect(ExecuteLog.store[Job4]).to satisfy { |v| v > ExecuteLog.store[Job3] }
    expect(ExecuteLog.store[InnerJob3]).to satisfy { |v| v > ExecuteLog.store[Job3] }
    expect(ExecuteLog.store[InnerJob1]).to satisfy { |v| v > ExecuteLog.store[Job3] }
    expect(ExecuteLog.store[InnerJob4]).to satisfy { |v| v > ExecuteLog.store[Job4] }
  end
end
