require 'rukawa/builtins/base'
require 'timeout'

module Rukawa
  module Builtins
    class Waiter < Base
      class_attribute :timeout, :poll_interval

      self.timeout = 1800
      self.poll_interval = 1

      class << self
        def handle_parameters(timeout: nil, poll_interval: nil, **rest)
          self.timeout = timeout if timeout
          self.poll_interval = poll_interval if poll_interval
        end
      end

      def run
        Timeout.timeout(timeout) do
          wait_until do
            fetch_condition
          end
        end
      end

      private

      def wait_until
        until yield
          sleep poll_interval
        end
      end

      def fetch_condition
        raise NotImplementedError
      end
    end

    class LocalFileWaiter < Waiter
      class_attribute :path

      class << self
        def handle_parameters(path:, **rest)
          self.path = path
          super(**rest)
        end
      end

      private

      def fetch_condition
        if path.respond_to?(:all?)
          path.all? { |p| File.exist?(p) }
        else
          File.exist?(path)
        end
      end
    end

    class S3Waiter < Waiter
      class_attribute :url, :aws_access_key_id, :aws_secret_access_key, :region
      
      class << self
        def handle_parameters(url:, aws_access_key_id: nil, aws_secret_access_key: nil, region: nil, **rest)
          require 'aws-sdk'

          self.url = url
          self.aws_access_key_id = aws_access_key_id if aws_access_key_id
          self.aws_secret_access_key = aws_secret_access_key if aws_secret_access_key
          self.region = region if region
          super(**rest)
        end
      end

      private

      def fetch_condition
        if url.respond_to?(:all?)
          url.all? do |u|
            s3url = URI.parse(u)
            client.head_object(bucket: s3url.host, key: s3url.path[1..-1]) rescue false
          end
        else
          s3url = URI.parse(url)
          client.head_object(bucket: s3url.host, key: s3url.path[1..-1]) rescue false
        end
      end

      def client
        return @client if @client

        if aws_secret_access_key || aws_secret_access_key || region
          options = {access_key_id: aws_access_key_id, secret_access_key: aws_secret_access_key, region: region}.reject do |_, v|
            v.nil?
          end
          @client = Aws::S3::Client.new(options)
        else
          @client = Aws::S3::Client.new
        end
      end
    end

    class GCSWaiter < Waiter
      class_attribute :url, :json_key
      
      class << self
        def handle_parameters(url:, json_key: nil, **rest)
          require 'google/apis/storage_v1'
          require 'googleauth'

          self.url = url
          self.json_key = json_key if json_key
          super(**rest)
        end
      end

      private

      def fetch_condition

        if url.respond_to?(:all?)
          url.all? do |u|
            gcsurl = URI.parse(u)
            client.list_objects(gcsurl.host, prefix: gcsurl.path[1..-1]).items.size > 0 rescue false
          end
        else
          gcsurl = URI.parse(url)
          client.list_objects(gcsurl.host, prefix: gcsurl.path[1..-1]).items.size > 0 rescue false
        end
      end

      def client
        return @client if @client

        client = Google::Apis::StorageV1::StorageService.new
        scope = "https://www.googleapis.com/auth/devstorage.read_only"

        if json_key
          begin
            JSON.parse(json_key)
            key = StringIO.new(json_key)
            client.authorization = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: key, scope: scope)
          rescue JSON::ParserError
            key = json_key
            File.open(json_key) do |f|
              client.authorization = Google::Auth::ServiceAccountCredentials.make_creds(json_key_io: f, scope: scope)
            end
          end
        else
          client.authorization = Google::Auth.get_application_default([scope])
        end
        client
      end
    end
  end
end
