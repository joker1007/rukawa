require 'concurrent'
require 'rukawa/dag_node'

module Rukawa
  class Job
    include DagNode

    def store(key, value)
      Rukawa.store[self.class] ||= Concurrent::Hash.new
      Rukawa.store[self.class][key] = value
    end

    def run
    end

    def to_dot_def
      if state == Rukawa::State::Waiting
        ""
      else
        "#{name} [color = #{state.color}];\n" unless state == Rukawa::State::Waiting
      end
    end

    def to_dot_from_nodes
      Array(name)
    end
    alias :to_dot_to_nodes :to_dot_from_nodes
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
