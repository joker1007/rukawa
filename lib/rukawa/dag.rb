require 'set'

module Rukawa
  class Dag
    include Enumerable
    include TSort

    def initialize(dependencies)
      deps = tsortable_hash(dependencies).tsort
      @root = RootJob.new
      @jobs = Set.new

      deps.each do |job_class|
        job = job_class.new
        @jobs << job

        if dependencies[job_class].empty?
          job.depend(@root)
        else
          dependencies[job_class].each do |parent_job|
            job.depend(@jobs.find { |j| j.instance_of?(parent_job) })
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
    alias :tsort_each_node :each

    def tsort_each_child(node, &block)
      node.out_jobs.each(&block)
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
  end
end
