# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe ActiveAdmin::PrimaryKey, "GraphQL identity columns" do
  it "falls back to the id column when ActiveRecord primary_key is blank" do
    expect(described_class.columns(StringIdRecord)).to eq(%w[id])
    expect(described_class.columns(IntegerIdRecord)).to eq(%w[id])
  end

  it "uses a configured non-id primary key" do
    expect(described_class.columns(AlternateKeyRecord)).to eq(%w[row_key])
  end

  it "rejects schema build when a model has neither primary key nor id column" do
    model = Class.new(ApplicationRecord) do
      self.table_name = "alternate_key_records"
      self.primary_key = nil
    end
    stub_const("OrphanKeyRow", model)

    ActiveAdmin::GraphQL.clear_schema_cache!
    load_resources do
      ActiveAdmin.application.namespaces[:admin].graphql = true
      ActiveAdmin.register(OrphanKeyRow)
    end

    expect {
      ActiveAdmin::GraphQL.schema_for(ActiveAdmin.application.namespaces[:admin])
    }.to raise_error(ArgumentError, /OrphanKeyRow.*(primary key|identity)/i)
  ensure
    ActiveAdmin::GraphQL.clear_schema_cache!
    load_resources {}
  end

  it "omits a model with neither primary key nor id column when graphql disable! is set" do
    model = Class.new(ApplicationRecord) do
      self.table_name = "alternate_key_records"
      self.primary_key = nil
    end
    stub_const("OrphanKeyRow", model)

    ActiveAdmin::GraphQL.clear_schema_cache!
    load_resources do
      ActiveAdmin.application.namespaces[:admin].graphql = true
      ActiveAdmin.register(Post)
      ActiveAdmin.register(OrphanKeyRow) { graphql { disable! } }
    end

    schema = ActiveAdmin::GraphQL.schema_for(ActiveAdmin.application.namespaces[:admin])
    type_names = schema.types.keys

    expect(type_names).to include("Post")
    expect(type_names).not_to include("OrphanKeyRow")
  ensure
    ActiveAdmin::GraphQL.clear_schema_cache!
    load_resources {}
  end

  it "keeps a non-id primary key inside the configured object-field allowlist" do
    ActiveAdmin::GraphQL.clear_schema_cache!
    load_resources do
      ActiveAdmin.application.namespaces[:admin].graphql = true
      ActiveAdmin.register(AlternateKeyRecord) do
        graphql { only :message }
      end
    end

    fields = ActiveAdmin::GraphQL.schema_for(
      ActiveAdmin.application.namespaces[:admin]
    ).types.fetch("AlternateKeyRecord").fields.keys

    expect(fields).to include("id", "message")
    expect(fields).not_to include("row_key")
  ensure
    ActiveAdmin::GraphQL.clear_schema_cache!
    load_resources {}
  end

  it "keeps a non-id primary key outside the configured object-field denylist" do
    ActiveAdmin::GraphQL.clear_schema_cache!
    load_resources do
      ActiveAdmin.application.namespaces[:admin].graphql = true
      ActiveAdmin.register(AlternateKeyRecord) do
        graphql { exclude :row_key }
      end
    end

    fields = ActiveAdmin::GraphQL.schema_for(
      ActiveAdmin.application.namespaces[:admin]
    ).types.fetch("AlternateKeyRecord").fields.keys

    expect(fields).to include("id", "message")
    expect(fields).not_to include("row_key")
  ensure
    ActiveAdmin::GraphQL.clear_schema_cache!
    load_resources {}
  end
end
