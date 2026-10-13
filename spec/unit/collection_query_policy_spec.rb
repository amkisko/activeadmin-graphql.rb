# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::GraphQL::CollectionQueryPolicy do
  let(:config) { ActiveAdmin::GraphQL::ResourceConfig.new }
  let(:aa_resource) { instance_double(ActiveAdmin::Resource, graphql_config: config) }

  before do
    config.assign_field_capabilities!(:pii, %i[body], mode: :null)
    config.assign_field_capabilities!(:editor, %i[title])
  end

  describe ".merge_field_grants" do
    it "infers grants from the resource field capability map" do
      grants = described_class.merge_field_grants(aa_resource, {})
      expect(grants).to eq("body" => :pii, "title" => :editor)
    end

    it "lets explicit field_grants override inferred entries" do
      grants = described_class.merge_field_grants(aa_resource, {"body" => :other})
      expect(grants["body"]).to eq(:other)
      expect(grants["title"]).to eq(:editor)
    end

    it "skips inference when infer is false" do
      grants = described_class.merge_field_grants(aa_resource, {"body" => :pii}, infer: false)
      expect(grants).to eq("body" => :pii)
    end
  end
end
