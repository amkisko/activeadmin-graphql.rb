# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::GraphQL::RunActionCapability do
  let(:namespace) { ActiveAdmin.application.namespaces[:admin] }
  let(:config) { ActiveAdmin::GraphQL::ResourceConfig.new }
  let(:aa_res) { instance_double(ActiveAdmin::Resource, graphql_config: config) }

  around do |example|
    previous_member = namespace.graphql_member_action_capability_default
    previous_batch = namespace.graphql_batch_action_capability_default
    previous_collection = namespace.graphql_collection_action_capability_default
    example.run
  ensure
    namespace.graphql_member_action_capability_default = previous_member
    namespace.graphql_batch_action_capability_default = previous_batch
    namespace.graphql_collection_action_capability_default = previous_collection
  end

  it "falls back to each kind's namespace default" do
    namespace.graphql_member_action_capability_default = :member_default
    namespace.graphql_batch_action_capability_default = :batch_default
    namespace.graphql_collection_action_capability_default = :collection_default

    expect(described_class.resolve(namespace, aa_res, :member, :publish)).to eq(:member_default)
    expect(described_class.resolve(namespace, aa_res, :batch, :star_these)).to eq(:batch_default)
    expect(described_class.resolve(namespace, aa_res, :collection, :export)).to eq(:collection_default)
  end

  it "prefers the resource capability map over the namespace default" do
    namespace.graphql_member_action_capability_default = :member_default
    config.assign_mutation_capabilities!(:mapped, %i[member_publish])

    expect(described_class.resolve(namespace, aa_res, :member, :publish)).to eq(:mapped)
  end

  it "prefers DSL capability on the per-action config" do
    namespace.graphql_member_action_capability_default = :member_default
    config.assign_mutation_capabilities!(:mapped, %i[member_publish])
    cfg = config.member_action_mutation_for(:publish)
    cfg.capability = :explicit

    expect(described_class.resolve(namespace, aa_res, :member, :publish)).to eq(:explicit)
  end
end
