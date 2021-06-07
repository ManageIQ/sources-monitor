require "rest-client"
require "sources-api-client"

module Sources
  module Monitor
    module Core
      module ApiClient
        INTERNAL_API_VERSION = 'v2.0'.freeze
        ORCHESTRATOR_TENANT = "system_orchestrator".freeze

        def page_size
          (ENV['PAGE_SIZE'] || 1000).to_i
        end

        def api_client(external_tenant = ORCHESTRATOR_TENANT)
          @sources_api_client ||= SourcesApiClient::ApiClient.new
          @api_client         ||= SourcesApiClient::DefaultApi.new(@sources_api_client)
          @sources_api_client.default_headers.merge!(identity(external_tenant))
          @api_client
        end

        def internal_api_get(collection, offset, limit)
          url = "#{SourcesApiClient.configure.scheme}://#{SourcesApiClient.configure.host}"
          JSON.parse(::RestClient.get("#{url}/internal/#{INTERNAL_API_VERSION}/#{collection}?offset=#{offset}&limit=#{limit}",
                                      identity(ORCHESTRATOR_TENANT).merge("Content-Type" => "application/json")))
        rescue ::RestClient::NotFound
          []
        end

        def identity(external_tenant)
          { "x-rh-identity" => Base64.strict_encode64({ "identity" => { "account_number" => external_tenant, "user" => { "is_org_admin" => true }}}.to_json) }
        end

        def paged_sources_get
          offset = 0

          loop do
            result = internal_api_get(:sources, offset, page_size)
            break if result['data'].blank?

            yield result['data']
            break if result['data'].length < page_size

            offset += page_size
          end
        end
      end
    end
  end
end
