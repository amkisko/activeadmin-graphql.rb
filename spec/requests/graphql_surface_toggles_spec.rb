# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "ActiveAdmin GraphQL surface toggles", type: :request do
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

  def mutation_type
    data = gql!(%({ __type(name: "Mutation") { name fields { name } } }))
    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    data.dig("data", "__type")
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
      yield ns
    end
    ActiveAdmin::GraphQL.clear_schema_cache!
  ensure
    previous&.each { |key, value| ns.public_send(:"#{key}=", value) }
  end

  context "when graphql_registered_resource_enabled is false" do
    around do |example|
      with_namespace_toggles(example, graphql_registered_resource_enabled: false) do
        ActiveAdmin.register(Post)
      end
    end

    it "omits registered_resource and the union type" do
      expect(query_field_names).not_to include("registered_resource")
      data = gql!(%({ __type(name: "ActiveAdminRegisteredResource") { name } }))
      expect(data.dig("data", "__type")).to be_nil
    end
  end

  context "when graphql_belongs_to_associations_enabled is false" do
    around do |example|
      with_namespace_toggles(example, graphql_belongs_to_associations_enabled: false) do
        ActiveAdmin.register(User)
        ActiveAdmin.register(Post)
      end
    end

    it "does not wire belongs_to fields onto resource objects" do
      expect(post_object_field_names).not_to include("author")
    end
  end

  context "when graphql_mutations_enabled_default is false" do
    around do |example|
      with_namespace_toggles(example, graphql_mutations_enabled_default: false) do
        ActiveAdmin.register(Post) { graphql { enable! } }
      end
    end

    it "omits CRUD mutations until enable_mutations!" do
      type = mutation_type
      names = type ? type.fetch("fields").map { |f| f.fetch("name") } : []
      expect(names).not_to include("create_post", "update_post", "delete_post", "destroy_post")
    end
  end

  context "when graphql_mutations_enabled_default is false and enable_mutations! is set" do
    around do |example|
      with_namespace_toggles(example, graphql_mutations_enabled_default: false) do
        ActiveAdmin.register(Post) { graphql { enable_mutations! } }
      end
    end

    it "includes CRUD mutations for that resource" do
      fields = mutation_type.fetch("fields").map { |f| f.fetch("name") }
      expect(fields).to include("create_post", "update_post", "delete_post", "destroy_post")
    end
  end

  context "when graphql_run_actions_enabled_default is false" do
    around do |example|
      with_namespace_toggles(example, graphql_run_actions_enabled_default: false) do
        ActiveAdmin.register(Post) do
          batch_action :flag do
          end
          graphql { enable! }
        end
      end
    end

    it "omits run-action mutations" do
      type = mutation_type
      names = type ? type.fetch("fields").map { |f| f.fetch("name") } : []
      expect(names).not_to include("posts_batch_action")
    end
  end

  context "when a resource calls disable_mutations!" do
    around do |example|
      with_namespace_toggles(example) do
        ActiveAdmin.register(Post) { graphql { disable_mutations! } }
      end
    end

    it "omits CRUD mutations for that resource" do
      type = mutation_type
      names = type ? type.fetch("fields").map { |f| f.fetch("name") } : []
      expect(names).not_to include("create_post", "update_post", "delete_post", "destroy_post")
    end
  end
end
