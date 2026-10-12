# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "ActiveAdmin GraphQL resource enabled default", type: :request do
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

  def with_opt_in_default(example)
    ns = ActiveAdmin.application.namespaces[:admin]
    previous = ns.graphql_resource_enabled_default
    ns.graphql_resource_enabled_default = false
    ActiveAdmin::GraphQL.clear_schema_cache!
    with_resources_during(example) do
      ns.graphql = true
      yield
    end
    ActiveAdmin::GraphQL.clear_schema_cache!
  ensure
    ns.graphql_resource_enabled_default = previous
  end

  context "when graphql_resource_enabled_default is false" do
    context "without a graphql block" do
      around do |example|
        with_opt_in_default(example) { ActiveAdmin.register(Post) }
      end

      it "omits the resource from the schema" do
        expect(query_field_names).not_to include("posts", "post")
      end
    end

    context "with an empty graphql block" do
      around do |example|
        with_opt_in_default(example) { ActiveAdmin.register(Post) { graphql {} } }
      end

      it "includes the resource in the schema" do
        expect(query_field_names).to include("posts", "post")
      end
    end

    context "with graphql enable!" do
      around do |example|
        with_opt_in_default(example) { ActiveAdmin.register(Post) { graphql { enable! } } }
      end

      it "includes the resource in the schema" do
        expect(query_field_names).to include("posts", "post")
      end
    end

    context "with graphql disable!" do
      around do |example|
        with_opt_in_default(example) { ActiveAdmin.register(Post) { graphql { disable! } } }
      end

      it "omits the resource from the schema" do
        expect(query_field_names).not_to include("posts", "post")
      end
    end
  end

  context "when graphql_resource_enabled_default stays true" do
    around do |example|
      ns = ActiveAdmin.application.namespaces[:admin]
      ActiveAdmin::GraphQL.clear_schema_cache!
      with_resources_during(example) do
        ns.graphql = true
        ActiveAdmin.register(Post)
      end
      ActiveAdmin::GraphQL.clear_schema_cache!
    end

    it "includes a resource that never calls graphql" do
      ns = ActiveAdmin.application.namespaces[:admin]
      expect(ns.graphql_resource_enabled_default).not_to be(false)
      expect(query_field_names).to include("posts", "post")
    end
  end
end
