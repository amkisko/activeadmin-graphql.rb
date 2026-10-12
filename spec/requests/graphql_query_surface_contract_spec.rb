# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "ActiveAdmin GraphQL query surface contract", type: :request do
  def gql!(query)
    post "/admin/graphql", params: {query: query}, as: :json
    JSON.parse(response.body)
  end

  def with_namespace_toggles(example, **toggles)
    ns = ActiveAdmin.application.namespaces[:admin]
    previous = toggles.keys.to_h { |key| [key, ns.public_send(key)] }
    toggles.each { |key, value| ns.public_send(:"#{key}=", value) }
    ActiveAdmin::GraphQL.clear_schema_cache!
    with_resources_during(example) do
      ns.graphql = true
      yield
    end
    ActiveAdmin::GraphQL.clear_schema_cache!
  ensure
    previous&.each { |key, value| ns.public_send(:"#{key}=", value) }
  end

  context "when graphql_queries_enabled_default is false" do
    around do |example|
      with_namespace_toggles(example, graphql_queries_enabled_default: false) do
        ActiveAdmin.register(Post) { graphql { enable_mutations! } }
      end
    end

    it "omits list, show, and registered_resource while keeping the object type for mutations" do
      data = gql!(<<~GQL)
        {
          queryFields: __type(name: "Query") { fields { name } }
          postType: __type(name: "Post") { name }
          unionType: __type(name: "ActiveAdminRegisteredResource") { name }
        }
      GQL
      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      names = data.dig("data", "queryFields", "fields").map { |f| f.fetch("name") }
      expect(names).to include("activeadmin_policies")
      expect(names).not_to include("posts", "post", "registered_resource")
      expect(data.dig("data", "postType", "name")).to eq("Post")
      expect(data.dig("data", "unionType")).to be_nil
    end
  end

  context "when Query would have no fields" do
    it "raises ActiveAdmin::DependencyError at schema build" do
      ns = ActiveAdmin.application.namespaces[:admin]
      previous = {
        graphql_queries_enabled_default: ns.graphql_queries_enabled_default,
        graphql_policies_enabled: ns.graphql_policies_enabled,
        graphql_registered_resource_enabled: ns.graphql_registered_resource_enabled
      }
      ns.graphql_queries_enabled_default = false
      ns.graphql_policies_enabled = false
      ns.graphql_registered_resource_enabled = false
      ActiveAdmin::GraphQL.clear_schema_cache!

      load_resources do
        ns.graphql = true
        ActiveAdmin.register(Post) { graphql { enable_mutations! } }
      end

      expect {
        ActiveAdmin::GraphQL.schema_for(ns)
      }.to raise_error(ActiveAdmin::DependencyError, /Query type has no fields/)
    ensure
      previous.each { |key, value| ns.public_send(:"#{key}=", value) }
      ActiveAdmin::GraphQL.clear_schema_cache!
      load_resources {}
    end
  end
end
