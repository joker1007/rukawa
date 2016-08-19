require 'rukawa/job'
require 'rukawa/wrapper'
require 'rukawa/remote/status_store'

module Rukawa
  module Wrapper
    module ActiveJob
      def self.[](job_class)
        raise "Please set Rukawa.config.status_store subclass of ActiveSupport::Cache::Store" unless Rukawa.config.status_store
        @wrapper_classes ||= {}
        return @wrapper_classes[job_class] if @wrapper_classes[job_class]

        wrapper = Class.new(Rukawa::Job) do
          define_singleton_method(:origin_class) do
            job_class
          end

          def initialize(parent_job_net, variables, context)
            super
            @job_class = self.class.origin_class
          end

          def run
            @job_class.include(Hooks) unless @job_class.include?(Hooks)
            @job_class.prepend(HooksForFailure) unless @job_class.include?(HooksForFailure)
            job = @job_class.perform_later

            status_store = Rukawa::Remote::StatusStore.new(job_id: job.job_id)
            finish_statuses = [Rukawa::Remote::StatusStore::COMPLETED, Rukawa::Remote::StatusStore::FAILED]
            until finish_statuses.include?(last_status = status_store.fetch)
              sleep 0.1
            end

            status_store.delete

            raise WrappedJobError if last_status == Rukawa::Remote::StatusStore::FAILED
          end
        end

        @wrapper_classes[job_class] = wrapper
        Rukawa::Wrapper.const_set("#{job_class.to_s.gsub(/::/, "_")}Wrapper", wrapper)
        wrapper
      end
    end

    module Hooks
      def self.included(base)
        base.class_eval do
          before_enqueue { status_store.enqueued }

          before_perform { status_store.performing }

          after_perform { status_store.completed }
        end
      end

      private

      def status_store
        @status_store ||= Rukawa::Remote::StatusStore.new(job_id: job_id)
      end
    end

    module HooksForFailure
      def perform(*args)
        super
      rescue Exception
        status_store.failed
        raise
      end
    end
  end
end
