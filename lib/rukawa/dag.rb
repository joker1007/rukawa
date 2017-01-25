require 'set'
require 'tsort'

module Rukawa
  class Dag
    include Enumerable
    include TSort

    attr_reader :nodes, :jobs, :edges

    def initialize
      @nodes = Set.new
      @jobs = Set.new
      @edges = Set.new
    end

    def build(job_net, variables, context, dependencies)
      deps = tsortable_hash(dependencies).tsort

      deps.each do |job_class|
        job = job_class.new(variables: variables, context: context, parent_job_net: job_net)
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

    def tsort_each_node(&block)
      @jobs.each(&block)
    end

    def tsort_each_child(node)
      if block_given?
        node.out_goings.each do |edge|
          yield edge.to
        end
      else
        Enumerator.new do |y|
          node.out_goings.each do |edge|
            y << edge.to
          end
        end
      end
    end

    def leveled_each
      visited = Set.new
      queue = []
      queue.push(*@jobs.select { |j| j.in_comings.empty? })

      if block_given?
        until queue.empty?
          next_job = queue.shift
          yield next_job unless visited.include?(next_job)
          queue.push(*next_job.out_goings.map(&:to)) if visited.add?(next_job)
        end
      else
        Enumerator.new do |y|
          until queue.empty?
            next_job = queue.shift
            y << next_job unless visited.include?(next_job)
            queue.push(*next_job.out_goings.map(&:to)) if visited.add?(next_job)
          end
        end
      end
    end

    private

    def tsortable_hash(hash)
      ensure_dependencies_have_all_jobs_as_key!(hash)
      class << hash
        include TSort
        alias :tsort_each_node :each_key
        def tsort_each_child(node, &block)
          fetch(node).each(&block)
        end
      end
      hash
    end

    def ensure_dependencies_have_all_jobs_as_key!(hash)
      hash.values.each do |parents|
        parents.each do |j|
          hash[j] ||= []
        end
      end
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
