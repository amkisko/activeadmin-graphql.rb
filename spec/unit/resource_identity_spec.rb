# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe ActiveAdmin::GraphQL::ResourceIdentity do
  def register_alert_event(**identity_kwargs)
    ActiveAdmin::GraphQL.clear_schema_cache!
    load_resources do
      ActiveAdmin.application.namespaces[:admin].graphql = true
      ActiveAdmin.register(Post)
      ActiveAdmin.register(AlertEvent) do
        graphql { identity(:entry_type, :entry_id, :event_type, **identity_kwargs) }
      end
    end
  end

  after do
    ActiveAdmin::GraphQL.clear_schema_cache!
    load_resources {}
  end

  it "builds a schema when identity columns are declared for a keyless view" do
    register_alert_event(separator: ":")

    schema = ActiveAdmin::GraphQL.schema_for(ActiveAdmin.application.namespaces[:admin])
    fields = schema.types.fetch("AlertEvent").fields.keys

    expect(fields).to include("id", "entry_type", "entry_id", "event_type", "payload")
  end

  it "encodes GraphQL id with the configured separator" do
    register_alert_event(separator: ":")
    aa_res = ActiveAdmin.application.namespaces[:admin].resource_for(AlertEvent)
    ActiveRecord::Base.connection.execute(
      "INSERT INTO alert_event_sources (entry_type, entry_id, event_type, payload) " \
      "VALUES ('Post', 9, 'created', 'ok')"
    )
    record = AlertEvent.find_by!(entry_type: "Post", entry_id: 9, event_type: "created")

    expect(described_class.graphql_id_value(aa_res, record)).to eq("Post:9:created")
    expect(described_class.graphql_id_value(aa_res, record)).to eq(record.id)
  end

  it "decodes a separator id into where attributes" do
    register_alert_event(separator: ":")
    aa_res = ActiveAdmin.application.namespaces[:admin].resource_for(AlertEvent)

    expect(described_class.attributes_for_id(aa_res, "Post:9:created")).to eq(
      "entry_type" => "Post",
      "entry_id" => "9",
      "event_type" => "created"
    )
  end

  it "uses encode and decode procs when provided" do
    register_alert_event(
      encode: ->(record) { record.id },
      decode: ->(id) {
        entry_type, entry_id, event_type = id.split(":", 3)
        {"entry_type" => entry_type, "entry_id" => entry_id, "event_type" => event_type}
      }
    )
    aa_res = ActiveAdmin.application.namespaces[:admin].resource_for(AlertEvent)
    ActiveRecord::Base.connection.execute(
      "INSERT INTO alert_event_sources (entry_type, entry_id, event_type, payload) " \
      "VALUES ('User', 3, 'updated', 'x')"
    )
    record = AlertEvent.find_by!(entry_type: "User", entry_id: 3, event_type: "updated")

    expect(described_class.graphql_id_value(aa_res, record)).to eq("User:3:updated")
    expect(described_class.attributes_for_id(aa_res, "User:3:updated")).to eq(
      "entry_type" => "User",
      "entry_id" => "3",
      "event_type" => "updated"
    )
  end

  it "mentions identity in the schema-build error when neither path is available" do
    model = Class.new(ApplicationRecord) do
      self.table_name = "alert_events"
      self.primary_key = nil
    end
    stub_const("OrphanAlertRow", model)

    ActiveAdmin::GraphQL.clear_schema_cache!
    load_resources do
      ActiveAdmin.application.namespaces[:admin].graphql = true
      ActiveAdmin.register(OrphanAlertRow)
    end

    expect {
      ActiveAdmin::GraphQL.schema_for(ActiveAdmin.application.namespaces[:admin])
    }.to raise_error(ArgumentError, /identity|primary key/i)
  end
end
