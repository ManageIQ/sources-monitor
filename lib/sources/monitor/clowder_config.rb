require 'app-common-ruby'
require 'singleton'
module Sources
  module Monitor

    class ClowderConfig
      include Singleton

      def self.instance
        @instance ||= {}.tap do |options|
          if ENV["CLOWDER_ENABLED"].present?
            config                        = LoadedConfig # TODO not an ideal name
            options["logGroup"]           = config.logging.cloudwatch.logGroup
            options["awsRegion"]          = config.logging.cloudwatch.region
            options["awsAccessKeyId"]     = config.logging.cloudwatch.accessKeyId
            options["awsSecretAccessKey"] = config.logging.cloudwatch.secretAccessKey
          else
            options["logGroup"]           = "platform-dev"
            options["awsRegion"]          = "us-east-1"
            options["awsAccessKeyId"]     = ENV['CW_AWS_ACCESS_KEY_ID']
            options["awsSecretAccessKey"] = ENV['CW_AWS_SECRET_ACCESS_KEY']
          end
        end
      end
    end
  end
end

# ManageIQ Logger depends on these variables
ENV['CW_AWS_ACCESS_KEY_ID']     = Sources::Monitor::ClowderConfig.instance["awsAccessKeyId"]
ENV['CW_AWS_SECRET_ACCESS_KEY'] = Sources::Monitor::ClowderConfig.instance["awsSecretAccessKey"]
