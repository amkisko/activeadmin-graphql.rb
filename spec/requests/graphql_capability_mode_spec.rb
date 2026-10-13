# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "ActiveAdmin GraphQL field capability_mode", type: :request do
  include GraphQLCapabilitiesRequestHelper

  context "when capability_mode is :null with visibility on" do
    around do |example|
      with_capabilities(example, capabilities_proc: ->(_ctx) { %i[editor] }) do
        ActiveAdmin.register(Post) do
          permit_params :title, :body, :starred
          graphql do
            capability :pii, fields: %i[body], mode: :null
            capability :editor, fields: %i[title], mode: :omit
          end
        end
      end
    end

    it "keeps null-mode fields in introspection and resolves them to null without the grant" do
      blog_post = Post.create!(title: "Visible", body: "secret", starred: false)

      intro = gql!(<<~GQL)
        { postFields: __type(name: "Post") { fields { name } } }
      GQL
      expect(response).to have_http_status(:ok)
      names = intro.dig("data", "postFields", "fields").map { |f| f.fetch("name") }
      expect(names).to include("body", "title")

      data = gql!(<<~GQL)
        { post(id: "#{blog_post.id}") { id title body } }
      GQL
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "post", "title")).to eq("Visible")
      expect(data.dig("data", "post", "body")).to be_nil
    end
  end

  context "when graphql_field_visible omits a field" do
    around do |example|
      ns = ActiveAdmin.application.namespaces[:admin]
      previous_hook = ns.graphql_field_visible
      ns.graphql_field_visible = lambda { |_ctx, meta|
        meta[:field_name] != "body"
      }
      with_capabilities(example, capabilities_proc: ->(_ctx) { %i[editor pii] }) do
        ActiveAdmin.register(Post) do
          graphql do
            capability :pii, fields: %i[body]
            capability :editor, fields: %i[title]
          end
        end
      end
    ensure
      ns.graphql_field_visible = previous_hook
    end

    it "omits the field from introspection even when the capability is granted" do
      data = gql!(<<~GQL)
        { postFields: __type(name: "Post") { fields { name } } }
      GQL
      expect(response).to have_http_status(:ok)
      names = data.dig("data", "postFields", "fields").map { |f| f.fetch("name") }
      expect(names).to include("title")
      expect(names).not_to include("body")
    end
  end
end
