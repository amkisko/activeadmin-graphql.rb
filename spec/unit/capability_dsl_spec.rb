# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::GraphQL::ResourceDefinitionDSL do
  let(:config) { ActiveAdmin::GraphQL::ResourceConfig.new }
  let(:dsl) { described_class.new(config) }

  it "associates multiple fields and mutations with one capability" do
    dsl.capability :editor do
      fields :title, :body
      queries :index, :show
      mutations :create, :update, :delete
    end

    expect(config.capability_for_field(:title)).to eq(:editor)
    expect(config.capability_for_field(:body)).to eq(:editor)
    expect(config.capability_for_query(:collection)).to eq(:editor)
    expect(config.capability_for_query(:member)).to eq(:editor)
    expect(config.capability_for_mutation(:create)).to eq(:editor)
    expect(config.capability_for_mutation(:update)).to eq(:editor)
    expect(config.capability_for_mutation(:destroy)).to eq(:editor)
  end

  it "accepts kwargs and member_actions sugar" do
    dsl.capability :publish, member_actions: %i[publish archive], batch_actions: %i[approve]

    expect(config.capability_for_mutation(:member_publish)).to eq(:publish)
    expect(config.capability_for_mutation(:member_archive)).to eq(:publish)
    expect(config.capability_for_mutation(:batch_approve)).to eq(:publish)
  end

  it "raises when the same member is assigned to two capabilities" do
    dsl.capability :a, fields: %i[title]
    expect {
      dsl.capability :b, fields: %i[title]
    }.to raise_error(ArgumentError, /title/)
  end

  it "stores field capability_mode from capability kwargs" do
    dsl.capability :pii, fields: %i[body], mode: :null
    expect(config.capability_for_field(:body)).to eq(:pii)
    expect(config.capability_mode_for_field(:body)).to eq(:null)
  end
end
