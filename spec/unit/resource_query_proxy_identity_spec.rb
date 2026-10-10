# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe ActiveAdmin::GraphQL::ResourceQueryProxy, "inferred identity" do
  around do |example|
    with_resources_during(example) { ActiveAdmin.register(IntegerIdRecord) }
  end

  let(:namespace) { ActiveAdmin.application.namespaces[:admin] }
  let(:aa_resource) { namespace.resource_for(IntegerIdRecord) }
  let(:proxy) do
    described_class.new(aa_resource: aa_resource, user: nil, namespace: namespace, graph_params: {})
  end

  it "finds one record and rejects an ambiguous member id" do
    IntegerIdRecord.insert_all!([{id: 41, name: "One"}, {id: 42, name: "Alpha"}, {id: 42, name: "Beta"}])

    expect(proxy.find_member(41).name).to eq("One")
    expect(proxy.find_member(43)).to be_nil
    expect { proxy.find_member(42) }.to raise_error(GraphQL::ExecutionError, /ambiguous GraphQL id/i)
  end

  it "preserves an explicitly configured ActiveAdmin finder" do
    load_resources do
      ActiveAdmin.register(IntegerIdRecord) do
        controller { defaults finder: :find_by_name! }
      end
    end
    IntegerIdRecord.insert_all!([{id: 42, name: "Named"}])
    configured_resource = namespace.resource_for(IntegerIdRecord)
    configured_proxy = described_class.new(
      aa_resource: configured_resource,
      user: nil,
      namespace: namespace,
      graph_params: {}
    )

    expect(configured_proxy.find_member("Named").name).to eq("Named")
  end

  it "rejects duplicate inferred ids in a batched lookup" do
    IntegerIdRecord.insert_all!([{id: 42, name: "Alpha"}, {id: 42, name: "Beta"}])

    expect { proxy.find_members([42]) }.to raise_error(GraphQL::ExecutionError, /ambiguous GraphQL id/i)
  end
end
