require "manageiq/messaging"
require "sources-api-client"
require "sources/monitor/availability_checker"

RSpec.describe(Sources::Monitor::AvailabilityChecker) do
  describe "Source.availability_check" do
    let(:orchestrator_tenant) { "system_orchestrator" }
    let(:identity) do
      { "x-rh-identity" => Base64.strict_encode64(
        { "identity" => { "account_number" => orchestrator_tenant, "user" => { "is_org_admin" => true } } }.to_json
      )}
    end
    let(:headers) { {"Content-Type" => "application/json"}.merge(identity) }

    let(:source_types_response) do
      {
        "data" => [
          {
            "id"           => "1",
            "name"         => "openshift",
            "product_name" => "OpenShift Container Platform",
            "vendor"       => "Red Hat"
          },
          {
            "id"           => "2",
            "name"         => "amazon",
            "product_name" => "Amazon Web Services",
            "vendor"       => "Amazon"
          }
        ]
      }.to_json
    end

    let(:sources) do
      [
        {
          "id"                  => "11",
          "source_type_id"      => "1",
          "tenant"              => "10001",
          "availability_status" => "available"
        },
        {
          "id"                  => "12",
          "source_type_id"      => "2",
          "tenant"              => "10002",
          "availability_status" => "available"
        },
        {
          "id"                  => "21",
          "source_type_id"      => "2",
          "tenant"              => "10001",
          "availability_status" => "unavailable"
        },
        {
          "id"                  => "22",
          "source_type_id"      => "2",
          "tenant"              => "10002",
          "availability_status" => "unavailable"
        }
      ]
    end

    it "fails with missing source state" do
      expect { described_class.new(nil).to raise_error("Must specify a Source state") }
    end

    it "fails with an invalid source state" do
      expect { described_class.new("bogus_state").to raise_error("Invalid Source state bogus_state specified") }
    end

    [1, 3, 1000].each do |page_size|
      context "with page size: #{page_size}" do
        around do |example|
          ENV['PAGE_SIZE'] = page_size.to_s
          example.run
          ENV['PAGE_SIZE'] = nil
        end

        before do
          stub_request(:get, "https://cloud.redhat.com/api/sources/v3.0/source_types")
            .with(:headers => headers)
            .to_return(:status => 200, :body => source_types_response, :headers => {})

          data = []
          if page_size == 1
            sources.size.times { |offset| data << {:data => [sources[offset]], :offset => offset } }
            data << {:data => [], :offset => 4}
          elsif page_size == 3
            data << {:data => sources[0..2], :offset => 0}
            data << {:data => [sources[3]], :offset => 3}
          else
            data << {:data => sources, :offset => 0}
          end

          data.each do |hash|
            stub_request(:get, "https://cloud.redhat.com/internal/v2.0/sources?limit=#{page_size}&offset=#{hash[:offset]}")
              .with(:headers => headers)
              .to_return(:status => 200, :body => {"data" => hash[:data]}.to_json, :headers => {})
          end

        end

        it "sends a request for an available source to the sources api" do
          instance = described_class.new("available")

          sources.each do |source|
            next if source['availability_status'] == 'unavailable'

            stub_request(:post, "https://cloud.redhat.com/api/sources/v3.0/sources/#{source["id"]}/check_availability")
              .with(:headers => headers.merge(instance.identity(source["tenant"])))
              .to_return(:status => 202, :body => "", :headers => {})
          end

          instance.check_sources

          sources.each do |source|
            next if source['availability_status'] == 'unavailable'

            assert_requested(:post,
                           "https://cloud.redhat.com/api/sources/v3.0/sources/#{source["id"]}/check_availability",
                           :headers => headers.merge(instance.identity(source["tenant"])),
                           :body    => "",
                           :times   => 1)
          end
        end

        it "sends a request for an unavailable source to the sources api" do
          instance = described_class.new("unavailable")

          sources.each do |source|
            next if source['availability_status'] == 'available'

            stub_request(:post, "https://cloud.redhat.com/api/sources/v3.0/sources/#{source["id"]}/check_availability")
              .with(:headers => headers.merge(instance.identity(source["tenant"])))
              .to_return(:status => 202, :body => "", :headers => {})
          end

          instance.check_sources

          sources.each do |source|
            next if source['availability_status'] == 'available'

            assert_requested(:post,
                             "https://cloud.redhat.com/api/sources/v3.0/sources/#{source["id"]}/check_availability",
                             :headers => headers.merge(instance.identity(source["tenant"])),
                             :body    => "",
                             :times   => 1)
          end
        end
      end
    end
  end
end
