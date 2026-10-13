# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "ActiveAdmin GraphQL collection query policy", type: :request do
  include GraphQLCapabilitiesRequestHelper

  context "when field grants are inferred from capability maps" do
    around do |example|
      ns = ActiveAdmin.application.namespaces[:admin]
      previous_policy = ns.graphql_collection_query_policy
      ns.graphql_collection_query_policy = lambda { |context, meta|
        ActiveAdmin::GraphQL::CollectionQueryPolicy.require_visible_fields!(
          context: context,
          aa_resource: meta[:aa_resource],
          q: meta[:q],
          order: meta[:order]
        )
      }
      with_capabilities(example, capabilities_proc: ->(_ctx) { %i[editor] }) do
        ActiveAdmin.register(Post) do
          graphql do
            capability :pii, fields: %i[body], mode: :null
            capability :editor do
              fields :title
              queries :index, :show
            end
          end
        end
      end
    ensure
      ns.graphql_collection_query_policy = previous_policy
    end

    it "rejects filters on null-mode fields when the inferred grant is missing" do
      Post.create!(title: "A", body: "secret", starred: false)
      data = gql!(<<~GQL)
        {
          posts(first: 5, q: { body_cont: "secret" }) {
            edges { node { title } }
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(Array(data["errors"]).pluck("message").join).to match(/filter on body/i)
    end

    it "allows filters on visible ungated fields" do
      Post.create!(title: "MatchMe", body: "x", starred: false)
      data = gql!(<<~GQL)
        {
          posts(first: 5, q: { title_cont: "Match" }) {
            edges { node { title } }
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      titles = data.dig("data", "posts", "edges").map { |e| e.dig("node", "title") }
      expect(titles).to eq(["MatchMe"])
    end

    it "allows filters on null-mode fields when the inferred grant is present" do
      ns = ActiveAdmin.application.namespaces[:admin]
      previous = ns.graphql_capabilities
      ns.graphql_capabilities = ->(_ctx) { %i[editor pii] }
      ActiveAdmin::GraphQL.clear_schema_cache!
      Post.create!(title: "B", body: "needle", starred: false)

      data = gql!(<<~GQL)
        {
          posts(first: 5, q: { body_cont: "needle" }) {
            edges { node { title } }
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      titles = data.dig("data", "posts", "edges").map { |e| e.dig("node", "title") }
      expect(titles).to eq(["B"])
    ensure
      ns.graphql_capabilities = previous
      ActiveAdmin::GraphQL.clear_schema_cache!
    end
  end

  context "when infer_field_grants is false" do
    around do |example|
      ns = ActiveAdmin.application.namespaces[:admin]
      previous_policy = ns.graphql_collection_query_policy
      ns.graphql_collection_query_policy = lambda { |context, meta|
        ActiveAdmin::GraphQL::CollectionQueryPolicy.require_visible_fields!(
          context: context,
          aa_resource: meta[:aa_resource],
          q: meta[:q],
          infer_field_grants: false
        )
      }
      with_capabilities(example, capabilities_proc: ->(_ctx) { %i[editor] }) do
        ActiveAdmin.register(Post) do
          graphql do
            capability :pii, fields: %i[body], mode: :null
            capability :editor do
              fields :title
              queries :index, :show
            end
          end
        end
      end
    ensure
      ns.graphql_collection_query_policy = previous_policy
    end

    it "does not require the capability when inference is off and field_grants is empty" do
      Post.create!(title: "A", body: "secret", starred: false)
      data = gql!(<<~GQL)
        {
          posts(first: 5, q: { body_cont: "secret" }) {
            edges { node { title } }
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
    end
  end
end
