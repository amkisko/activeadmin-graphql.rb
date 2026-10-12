# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "ActiveAdmin GraphQL capability edges", type: :request do
  context "when a belongs_to association is capability-gated" do
    around do |example|
      with_capabilities(example, capabilities_proc: ->(_ctx) { granted_capabilities }, visibility: nil) do
        ActiveAdmin.register(User)
        ActiveAdmin.register(Post) do
          graphql do
            capability :pii, fields: %i[author]
          end
        end
      end
    end

    let(:granted_capabilities) { [] }
    let(:author) { User.create!(first_name: "Ada", last_name: "Lovelace") }
    let!(:blog_post) { Post.create!(title: "T", body: "B", author: author) }

    it "returns null for the association without the capability" do
      data = gql!(<<~GQL)
        { post(id: "#{blog_post.id}") { id author { id } } }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data.dig("data", "post", "id")).to eq(blog_post.id.to_s)
      expect(data.dig("data", "post", "author")).to be_nil
    end

    context "when the capability is granted" do
      let(:granted_capabilities) { %i[pii] }

      it "resolves the association" do
        data = gql!(<<~GQL)
          { post(id: "#{blog_post.id}") { id author { id } } }
        GQL

        expect(response).to have_http_status(:ok)
        expect(data["errors"]).to be_nil
        expect(data.dig("data", "post", "author", "id")).to eq(author.id.to_s)
      end
    end
  end

  context "when graphql_capabilities is combined with named visibility profiles" do
    it "raises at schema build" do
      ns = ActiveAdmin.application.namespaces[:admin]
      previous_capabilities = ns.graphql_capabilities
      previous_visibility = ns.graphql_visibility
      ns.graphql_capabilities = ->(_ctx) { %i[editor] }
      ns.graphql_visibility = {
        preload: false,
        profiles: {default: {}}
      }
      ActiveAdmin::GraphQL.clear_schema_cache!
      begin
        load_resources do
          ns.graphql = true
          ActiveAdmin.register(Post) do
            graphql do
              capability :editor, fields: %i[title]
            end
          end
        end
        expect {
          ActiveAdmin::GraphQL.schema_for(ns)
        }.to raise_error(ActiveAdmin::DependencyError, /named GraphQL visibility profiles/)
      ensure
        ns.graphql_capabilities = previous_capabilities
        ns.graphql_visibility = previous_visibility
        ActiveAdmin::GraphQL.clear_schema_cache!
        load_resources {}
      end
    end
  end

  context "when consecutive requests grant different capabilities" do
    around do |example|
      with_capabilities(
        example,
        capabilities_proc: ->(_ctx) { granted_capabilities },
        visibility: {preload: false},
        visibility_profile: :ignored_when_capabilities
      ) do
        ActiveAdmin.register(Post) do
          graphql do
            capability :editor, fields: %i[title]
          end
        end
      end
    end

    let(:granted_capabilities) { [] }
    let!(:blog_post) { Post.create!(title: "Secret", body: "B", starred: false) }

    it "hides then reveals the field across requests on the same schema" do
      denied = gql!(<<~GQL)
        { post(id: "#{blog_post.id}") { id title } }
      GQL
      expect(response).to have_http_status(:ok)
      expect(Array(denied["errors"]).pluck("message").join).to match(/title|Field|undefined/i)

      granted_capabilities.replace(%i[editor])
      allowed = gql!(<<~GQL)
        { post(id: "#{blog_post.id}") { id title } }
      GQL
      expect(response).to have_http_status(:ok)
      expect(allowed["errors"]).to be_nil
      expect(allowed.dig("data", "post", "title")).to eq("Secret")
    end
  end

  context "when a capability field name is unknown" do
    it "raises at schema build" do
      ns = ActiveAdmin.application.namespaces[:admin]
      previous_capabilities = ns.graphql_capabilities
      previous_visibility = ns.graphql_visibility
      ns.graphql_capabilities = ->(_ctx) { [] }
      ns.graphql_visibility = {preload: false}
      ActiveAdmin::GraphQL.clear_schema_cache!
      begin
        load_resources do
          ns.graphql = true
          ActiveAdmin.register(Post) do
            graphql do
              capability :pii, fields: %i[not_a_real_field]
            end
          end
        end
        expect {
          ActiveAdmin::GraphQL.schema_for(ns)
        }.to raise_error(ActiveAdmin::DependencyError, /not_a_real_field/)
      ensure
        ns.graphql_capabilities = previous_capabilities
        ns.graphql_visibility = previous_visibility
        ActiveAdmin::GraphQL.clear_schema_cache!
        load_resources {}
      end
    end
  end
end
