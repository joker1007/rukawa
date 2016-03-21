require 'set'

module Rukawa
  class Dag
    include Enumerable

    attr_reader :jobs, :edges

    def initialize(job_net, dependencies)
      deps = tsortable_hash(dependencies).tsort
      @jobs = Set.new
      @edges = Set.new

      deps.each do |job_class|
        job = job_class.new(job_net)
        @jobs << job

        dependencies[job_class].each do |depend_job_class|
          depend_job = @jobs.find { |j| j.instance_of?(depend_job_class) }

          depend_job.nodes_as_from.product(job.nodes_as_to).each do |from, to|
            edge = Edge.new(from, to, job_net)
            @edges << edge
            from.out_goings << edge
            to.in_comings << edge
          end
        end
      end
    end

    def each
      if block_given?
        @jobs.each { |j| yield j }
      else
        @jobs.each
      end
    end

    def roots
      select(&:root?)
    end

    def leaves
      select(&:leaf?)
    end

    private

    def tsortable_hash(hash)
      class << hash
        include TSort
        alias :tsort_each_node :each_key
        def tsort_each_child(node, &block)
          fetch(node).each(&block)
        end
      end
      hash
    end

    class Edge
      attr_reader :from, :to, :cluster

      def initialize(from, to, cluster = nil)
        @from, @to, @cluster = from, to, cluster
      end

      def inspect
        "#{@from.name} -> #{@to.name}"
      end

      def ==(edge)
        return false unless edge.is_a?(Edge)
        from == edge.from && to == edge.to
      end
      alias :eql? :==

      def hash
        [from, to].hash
      end
    end
  end
end
