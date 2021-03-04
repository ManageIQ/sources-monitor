require 'clowder-common-ruby'
require 'singleton'

module Sources
  module Monitor
    class ClowderConfig
      include Singleton

      def self.instance
        @instance ||= {}.tap do |options|
          if ::ClowderCommonRuby::Config.clowder_enabled?
            config                        = ::ClowderCommonRuby::Config.load
            options["awsAccessKeyId"]     = config.logging.cloudwatch.accessKeyId
            options["awsRegion"]          = config.logging.cloudwatch.region
            options["awsSecretAccessKey"] = config.logging.cloudwatch.secretAccessKey
            options["logGroup"]           = config.logging.cloudwatch.logGroup
          else
            options["awsAccessKeyId"]     = ENV['CW_AWS_ACCESS_KEY_ID']
            options["awsRegion"]          = "us-east-1"
            options["awsSecretAccessKey"] = ENV['CW_AWS_SECRET_ACCESS_KEY']
            options["logGroup"]           = "platform-dev"
          end
        end
      end
    end
  end
end

# ManageIQ Logger depends on these variables
ENV['CW_AWS_ACCESS_KEY_ID']     = Sources::Monitor::ClowderConfig.instance["awsAccessKeyId"]
ENV['CW_AWS_SECRET_ACCESS_KEY'] = Sources::Monitor::ClowderConfig.instance["awsSecretAccessKey"]
