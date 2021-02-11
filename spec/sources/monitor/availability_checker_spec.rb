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

    let(:tenants_response) do
      [{"external_tenant" => orchestrator_tenant}].to_json
    end

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

    let(:available_source) do
      {
        "id"                  => "11",
        "source_type_id"      => "1",
        "tenant"              => "10001",
        "availability_status" => "available"
      }
    end

    let(:unavailable_source) do
      {
        "id"                  => "12",
        "source_type_id"      => "2",
        "tenant"              => "10002",
        "availability_status" => "unavailable"
      }
    end

    let(:sources_response) do
      {
        "data" => [
          available_source,
          unavailable_source
        ]
      }.to_json
    end

    let(:openshift_payload) do
      {
        :params => a_hash_including(
          :source_id       => "11",
          :external_tenant => "10001"
        )
      }
    end

    let(:amazon_payload) do
      {
        :params => a_hash_including(
          :source_id       => "12",
          :external_tenant => "10002"
        )
      }
    end

    it "fails with missing source state" do
      expect { described_class.new(nil).to raise_error("Must specify a Source state") }
    end

    it "fails with an invalid source state" do
      expect { described_class.new("bogus_state").to raise_error("Invalid Source state bogus_state specified") }
    end

    it "sends a request for an available source to the sources api" do
      instance = described_class.new("available")

      stub_request(:get, "https://cloud.redhat.com/internal/v1.0/tenants")
        .with(:headers => headers)
        .to_return(:status => 200, :body => tenants_response, :headers => {})
      stub_request(:get, "https://cloud.redhat.com/api/sources/v1.0/source_types")
        .with(:headers => headers)
        .to_return(:status => 200, :body => source_types_response, :headers => {})
      stub_request(:get, "https://cloud.redhat.com/api/sources/v1.0/sources?limit=1000&offset=0")
        .with(:headers => headers)
        .to_return(:status => 200, :body => sources_response, :headers => {})
      stub_request(:post, "https://cloud.redhat.com/api/sources/v1.0/sources/#{available_source["id"]}/check_availability")
        .with(:headers => headers.merge(instance.identity(available_source["tenant"])))
        .to_return(:status => 202, :body => "", :headers => {})

      instance.check_sources

      assert_requested(:post,
                       "https://cloud.redhat.com/api/sources/v1.0/sources/#{available_source["id"]}/check_availability",
                       :headers => headers.merge(instance.identity(available_source["tenant"])),
                       :body    => "",
                       :times   => 1)
    end

    it "sends a request for an unavailable source to the sources api" do
      instance = described_class.new("unavailable")

      stub_request(:get, "https://cloud.redhat.com/internal/v1.0/tenants")
        .with(:headers => headers)
        .to_return(:status => 200, :body => tenants_response, :headers => {})
      stub_request(:get, "https://cloud.redhat.com/api/sources/v1.0/source_types")
        .with(:headers => headers)
        .to_return(:status => 200, :body => source_types_response, :headers => {})
      stub_request(:get, "https://cloud.redhat.com/api/sources/v1.0/sources?limit=1000&offset=0")
        .with(:headers => headers)
        .to_return(:status => 200, :body => sources_response, :headers => {})
      stub_request(:post, "https://cloud.redhat.com/api/sources/v1.0/sources/#{unavailable_source["id"]}/check_availability")
        .with(:headers => headers.merge(instance.identity(unavailable_source["tenant"])))
        .to_return(:status => 202, :body => "", :headers => {})

      instance.check_sources

      assert_requested(:post,
                       "https://cloud.redhat.com/api/sources/v1.0/sources/#{unavailable_source["id"]}/check_availability",
                       :headers => headers.merge(instance.identity(unavailable_source["tenant"])),
                       :body    => "",
                       :times   => 1)
    end
  end
end
