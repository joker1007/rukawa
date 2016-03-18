require 'concurrent'
require 'rukawa/dag_node'

module Rukawa
  class Job
    include DagNode
    attr_reader :state
    STATES = %i(waiting running finished error).freeze

    def store(key, value)
      Rukawa.store[self.class] ||= Concurrent::Hash.new
      Rukawa.store[self.class][key] = value
    end

    def run
    end
  end

  class RootJob < Job
    def dataflow
      return @dataflow if @dataflow

      @dataflow = Concurrent.dataflow_with(Rukawa.executor, *depend_dataflows) do |*results|
        true
      end
    end
  end
end
