# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "ActiveAdmin GraphQL policy surface", type: :request do
  def gql!(query)
    post "/admin/graphql", params: {query: query}, as: :json
    JSON.parse(response.body)
  end

  def query_field_names
    data = gql!(%({ __type(name: "Query") { fields { name } } }))
    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    data.dig("data", "__type", "fields").map { |f| f.fetch("name") }
  end

  def post_object_field_names
    data = gql!(%({ __type(name: "Post") { fields { name } } }))
    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    data.dig("data", "__type", "fields").map { |f| f.fetch("name") }
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

  context "when graphql_policies_enabled is false" do
    around do |example|
      with_namespace_toggles(example, graphql_policies_enabled: false) do
        ActiveAdmin.register(Post)
      end
    end

    it "omits policy query fields and the object policy field" do
      names = query_field_names
      expect(names).to include("posts", "post")
      expect(names).not_to include("activeadmin_policies", "activeadmin_policies_for")
      expect(post_object_field_names).not_to include("activeadmin_policies")
    end
  end

  context "when graphql_policy_adapter is a custom class" do
    around do |example|
      adapter = Class.new(ActiveAdmin::GraphQL::PolicyAdapter) do
        def policy_set(**)
          {
            allowed_actions: %w[read],
            allowed_member_actions: [],
            allowed_collection_actions: [],
            allowed_batch_actions: []
          }
        end
      end
      with_namespace_toggles(example, graphql_policy_adapter: adapter) do
        ActiveAdmin.register(Post)
      end
    end

    it "uses the adapter for policy payloads" do
      Post.create!(title: "Policy adapter", body: "b")
      data = gql!(<<~GQL)
        {
          activeadmin_policies {
            resources {
              type_name
              activeadmin_policies { allowed_actions }
            }
          }
        }
      GQL
      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      post_row = data.dig("data", "activeadmin_policies", "resources").find { |r| r["type_name"] == "Post" }
      expect(post_row.dig("activeadmin_policies", "allowed_actions")).to eq(%w[read])
    end
  end

  context "when graphql_policies_enabled_default is false" do
    around do |example|
      with_namespace_toggles(example, graphql_policies_enabled_default: false) do
        ActiveAdmin.register(Post) { graphql { enable! } }
      end
    end

    it "keeps policy query fields but omits the object field until enable_policies!" do
      expect(query_field_names).to include("activeadmin_policies")
      expect(post_object_field_names).not_to include("activeadmin_policies")
    end
  end

  context "when a resource calls disable_policies!" do
    around do |example|
      with_namespace_toggles(example) do
        ActiveAdmin.register(Post) { graphql { disable_policies! } }
      end
    end

    it "keeps global policy queries but omits the object field for that resource" do
      expect(query_field_names).to include("activeadmin_policies")
      expect(post_object_field_names).not_to include("activeadmin_policies")

      data = gql!(<<~GQL)
        { activeadmin_policies { resources { type_name } } }
      GQL
      type_names = data.dig("data", "activeadmin_policies", "resources").map { |r| r.fetch("type_name") }
      expect(type_names).not_to include("Post")
    end
  end
end
