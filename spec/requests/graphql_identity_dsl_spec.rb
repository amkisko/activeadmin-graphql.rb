# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "ActiveAdmin GraphQL identity DSL", type: :request do
  around do |example|
    ActiveAdmin::GraphQL.clear_schema_cache!
    with_resources_during(example) do
      ActiveAdmin.application.namespaces[:admin].graphql = true
      ActiveAdmin.register(Post)
      ActiveAdmin.register(AlertEvent) do
        graphql { identity :entry_type, :entry_id, :event_type, separator: ":" }
      end
    end
    ActiveAdmin::GraphQL.clear_schema_cache!
  end

  def gql!(query, variables = nil)
    body = {query: query}
    body[:variables] = variables if variables
    post "/admin/graphql", params: body, as: :json
    JSON.parse(response.body)
  end

  def insert_alert!(entry_type:, entry_id:, event_type:, payload: "p")
    ActiveRecord::Base.connection.execute(
      "INSERT INTO alert_event_sources (entry_type, entry_id, event_type, payload) " \
      "VALUES ('#{entry_type}', #{entry_id}, '#{event_type}', '#{payload}')"
    )
  end

  it "lists and loads a keyless view row by configured identity" do
    insert_alert!(entry_type: "Post", entry_id: 11, event_type: "created", payload: "hello")

    data = gql!(<<~GQL)
      {
        alert_events(first: 5) {
          edges { node { id entry_type entry_id event_type payload } }
        }
        alertEvent(id: "Post:11:created") {
          id
          payload
        }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    expect(data.dig("data", "alert_events", "edges", 0, "node")).to include(
      "id" => "Post:11:created",
      "entry_type" => "Post",
      "entry_id" => 11,
      "event_type" => "created",
      "payload" => "hello"
    )
    expect(data.dig("data", "alertEvent")).to eq(
      "id" => "Post:11:created",
      "payload" => "hello"
    )
  end

  it "fails closed when a configured identity matches more than one row" do
    insert_alert!(entry_type: "Post", entry_id: 12, event_type: "dup", payload: "a")
    insert_alert!(entry_type: "Post", entry_id: 12, event_type: "dup", payload: "b")

    data = gql!(<<~GQL)
      {
        alertEvent(id: "Post:12:dup") { id }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"].to_s).to match(/ambiguous GraphQL id/i)
  end
end
