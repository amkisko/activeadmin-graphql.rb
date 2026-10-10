# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "ActiveAdmin GraphQL identity columns", type: :request do
  around do |example|
    ActiveAdmin::GraphQL.clear_schema_cache!
    with_resources_during(example) do
      ActiveAdmin.application.namespaces[:admin].graphql = true
      ActiveAdmin.register(Post)
      ActiveAdmin.register(StringIdRecord)
      ActiveAdmin.register(IntegerIdRecord)
      ActiveAdmin.register(AlternateKeyRecord)
    end
    ActiveAdmin::GraphQL.clear_schema_cache!
  end

  def gql!(query, variables = nil)
    body = {query: query}
    body[:variables] = variables if variables
    post "/admin/graphql", params: body, as: :json
    JSON.parse(response.body)
  end

  def graphql_type_unwrap_name(type_json)
    t = type_json
    while t && %w[NON_NULL LIST].include?(t["kind"])
      t = t["ofType"]
    end
    t&.fetch("name", nil)
  end

  it "builds and introspects the full registered schema without duplicate id fields" do
    data = gql!(<<~GQL)
      {
        __schema {
          types { name kind }
        }
        stringIdRecord: __type(name: "StringIdRecord") {
          fields { name type { kind name ofType { kind name } } }
        }
        integerIdRecord: __type(name: "IntegerIdRecord") {
          fields { name type { kind name ofType { kind name } } }
        }
        alternateKeyRecord: __type(name: "AlternateKeyRecord") {
          fields { name type { kind name ofType { kind name } } }
        }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil

    type_names = data.dig("data", "__schema", "types").map { |t| t.fetch("name") }
    expect(type_names).to include("StringIdRecord", "IntegerIdRecord", "AlternateKeyRecord", "Post")

    %w[stringIdRecord integerIdRecord alternateKeyRecord].each do |key|
      fields = data.dig("data", key, "fields")
      id_fields = fields.select { |f| f.fetch("name") == "id" }
      expect(id_fields.size).to eq(1)
      expect(graphql_type_unwrap_name(id_fields.first.fetch("type"))).to eq("ID")
    end

    alternate_names = data.dig("data", "alternateKeyRecord", "fields").map { |f| f.fetch("name") }
    expect(alternate_names).to include("id", "row_key", "message")
  end

  it "exposes a single GraphQL id for a view with an id column and unset primary_key" do
    ActiveRecord::Base.connection.execute(
      "INSERT INTO string_id_sources (code, label) VALUES ('row-9', 'Box')"
    )
    ActiveRecord::Base.connection.execute(
      "INSERT INTO integer_id_records (id, name) VALUES (42, 'Alpha')"
    )

    data = gql!(<<~GQL)
      {
        string_id_records(first: 5) { edges { node { id label } } }
        integer_id_records(first: 5) { edges { node { id name } } }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    expect(data.dig("data", "string_id_records", "edges", 0, "node")).to include(
      "id" => "row-9",
      "label" => "Box"
    )
    expect(data.dig("data", "integer_id_records", "edges", 0, "node")).to include(
      "id" => "42",
      "name" => "Alpha"
    )
  end

  it "loads one view record by its inferred id column" do
    ActiveRecord::Base.connection.execute(
      "INSERT INTO string_id_sources (code, label) VALUES ('row-10', 'Crate')"
    )

    data = gql!(<<~GQL)
      {
        stringIdRecord(id: "row-10") { id label }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    expect(data.dig("data", "stringIdRecord")).to eq(
      "id" => "row-10",
      "label" => "Crate"
    )
  end

  it "uses a non-id primary key on a view without an id column" do
    ActiveRecord::Base.connection.execute(
      "INSERT INTO alternate_key_sources (id, message) VALUES (7, 'ping')"
    )

    data = gql!(<<~GQL)
      {
        alternate_key_records(first: 5) { edges { node { id row_key message } } }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    expect(data.dig("data", "alternate_key_records", "edges", 0, "node")).to include(
      "id" => "7",
      "row_key" => 7,
      "message" => "ping"
    )
  end
end
