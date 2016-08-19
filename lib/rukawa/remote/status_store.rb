module Rukawa
  module Remote
    class StatusStore
      ENQUEUED = "enqueued".freeze
      PERFORMING = "performing".freeze
      COMPLETED = "completed".freeze
      FAILED = "failed".freeze

      # default expire duration is 24 hours.
      def initialize(job_id:, expire_duration: Rukawa.config.status_expire_duration)
        @job_id = job_id
        @expire_duration = expire_duration
      end

      def fetch
        Rukawa.config.status_store.fetch(store_key)
      end

      def enqueued
        Rukawa.config.status_store.write(store_key, ENQUEUED, expires_in: @expire_duration)
      end

      def performing
        Rukawa.config.status_store.write(store_key, PERFORMING, expires_in: @expire_duration)
      end

      def completed
        Rukawa.config.status_store.write(store_key, COMPLETED, expires_in: @expire_duration)
      end

      def failed
        Rukawa.config.status_store.write(store_key, FAILED, expires_in: @expire_duration)
      end

      def delete
        Rukawa.config.status_store.delete(store_key)
      end

      private

      def store_key
        "rukawa.remote_job.status.#{@job_id}"
      end
    end
  end
end
