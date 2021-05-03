require "insights/loggers"

module Sources
  module Monitor
    APP_NAME = "sources-monitor".freeze

    class << self
      attr_writer :logger
    end

    def self.logger_class
      if ENV['LOG_HANDLER'] == "haberdasher"
        "Insights::Loggers::StdErrLogger"
      else
        "ManageIQ::Loggers::CloudWatch"
      end
    end

    def self.logger
      @logger ||= Insights::Loggers::Factory.create_logger(logger_class, :app_name => APP_NAME)
    end

    module Logging
      def logger
        Sources::Monitor.logger
      end
    end
  end
end
