require 'set'

module Rukawa
  class Dag
    include Enumerable

    attr_reader :nodes, :jobs, :edges

    def initialize
      @nodes = Set.new
      @jobs = Set.new
      @edges = Set.new
    end

    def build(job_net, dependencies)
      deps = tsortable_hash(dependencies).tsort

      deps.each do |job_class|
        job = job_class.new(job_net)
        @nodes << job
        @jobs << job if job.is_a?(Job)

        dependencies[job_class].each do |depend_job_class|
          depend_job = @nodes.find { |j| j.instance_of?(depend_job_class) }

          depend_job.jobs_as_from.product(job.jobs_as_to).each do |from, to|
            @jobs << from
            @jobs << to
            edge = Edge.new(from, to, job_net)
            @edges << edge
            from.out_goings << edge
            to.in_comings << edge
          end
        end
      end

      if job_net.parent_job_net
        job_net.parent_job_net.dag.jobs.merge(@jobs)
      end
    end

    def each
      if block_given?
        @nodes.each { |j| yield j }
      else
        @nodes.each
      end
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
