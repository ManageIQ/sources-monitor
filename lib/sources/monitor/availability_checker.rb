require "sources/monitor/core/api_client"
require "sources/monitor/core/logging"
require "sources/monitor/core/messaging"

module Sources
  module Monitor
    class AvailabilityChecker
      include Logging
      include Core::ApiClient
      include Core::Messaging

      SUPPORTED_STATES = %w[available unavailable].freeze

      attr_accessor :source_state

      def initialize(source_state)
        raise "Must specify a Source state" if source_state.blank?
        raise "Invalid Source state #{source_state} specified" unless SUPPORTED_STATES.include?(source_state)

        @source_state = source_state
      end

      def check_sources
        logger.info("AvailabilityChecker started for #{source_state} Sources")
        fetch_sources.each do |source|
          request_availability_check(source)
        end
      end

      private

      def fetch_sources
        source_type_name = Hash[api_client.list_source_types.data.collect { |st| [st.id, st.name] }]

        sources = []
        internal_api_get(:tenants).each do |tenant|
          paged_query(api_client(tenant["external_tenant"]), :list_sources).each do |source|
            next unless availability_status_matches(source, source_state)

            sources << {
              :id     => source.id.to_s,
              :tenant => source.tenant,
              :type   => source_type_name[source.source_type_id]
            }
          end
        end
        sources.uniq
      rescue => e
        logger.error("Failed to query #{source_state} Sources - #{e.message}")
        []
      end

      def availability_status_matches(source, source_state)
        sas = source.availability_status
        source_state == "available" ? sas == "available" : sas != "available"
      end

      def request_availability_check(source)
        logger.info("Requesting Source.availability_check [#{
          {
            "source_type"     => source[:type],
            "source_id"       => source[:id],
            "external_tenant" => source[:tenant]
          }}]")

        api_client(source[:tenant]).check_availability_source(source[:id])
      rescue SourcesApiClient::ApiError => e
        error_message = JSON.parse(e.response_body)["errors"].first["detail"]
        logger.error("Failed to request availability_check for Source id: #{source[:id]} type: #{source[:type]} tenant: #{source[:tenant]} - #{error_message}")
      rescue => e
        logger.error("Failed to request availability_check for Source id: #{source[:id]} type: #{source[:type]} tenant: #{source[:tenant]} - #{e.message}")
      end
    end
  end
end
