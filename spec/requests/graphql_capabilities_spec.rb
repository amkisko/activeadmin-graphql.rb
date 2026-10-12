# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "ActiveAdmin GraphQL capabilities", type: :request do
  def register_capable_post!
    ActiveAdmin.register(Post) do
      permit_params :title, :body, :starred
      graphql do
        capability :pii do
          fields :body
        end
        capability :editor do
          fields :title
          queries :index, :show
          mutations :create, :update
        end
      end
    end
  end

  context "when fields and mutations share capabilities" do
    around do |example|
      with_capabilities(example, capabilities_proc: ->(_ctx) { %i[editor] }) do
        register_capable_post!
      end
    end

    it "keeps granted fields and mutations in introspection" do
      data = gql!(<<~GQL)
        {
          postFields: __type(name: "Post") { fields { name } }
          queryFields: __type(name: "Query") { fields { name } }
          mutationFields: __type(name: "Mutation") { fields { name } }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      post_fields = data.dig("data", "postFields", "fields").map { |f| f.fetch("name") }
      expect(post_fields).to include("title", "starred")
      expect(post_fields).not_to include("body")

      query_fields = data.dig("data", "queryFields", "fields").map { |f| f.fetch("name") }
      expect(query_fields).to include("posts", "post")

      mutation_fields = data.dig("data", "mutationFields", "fields").map { |f| f.fetch("name") }
      expect(mutation_fields).to include("create_post", "update_post")
      expect(mutation_fields).to include("delete_post", "destroy_post")
    end

    it "resolves granted fields and rejects a query that selects a hidden field" do
      blog_post = Post.create!(title: "Secret body", body: "hidden", starred: false)
      ok = gql!(<<~GQL)
        { post(id: "#{blog_post.id}") { id title } }
      GQL
      expect(response).to have_http_status(:ok)
      expect(ok["errors"]).to be_nil
      expect(ok.dig("data", "post", "title")).to eq("Secret body")

      bad = gql!(<<~GQL)
        { post(id: "#{blog_post.id}") { id title body } }
      GQL
      expect(response).to have_http_status(:ok)
      expect(Array(bad["errors"]).pluck("message").join).to match(/body|Field|undefined/i)
    end
  end

  context "when visibility is off and a field capability is missing" do
    around do |example|
      with_capabilities(example, capabilities_proc: ->(_ctx) { %i[editor] }, visibility: nil) do
        register_capable_post!
      end
    end

    it "returns null for the gated field and keeps sibling fields" do
      blog_post = Post.create!(title: "Visible title", body: "hidden", starred: false)
      data = gql!(<<~GQL)
        { post(id: "#{blog_post.id}") { id title body } }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data.dig("data", "post", "title")).to eq("Visible title")
      expect(data.dig("data", "post", "body")).to be_nil
    end
  end

  context "when no capabilities are granted" do
    around do |example|
      with_capabilities(example, capabilities_proc: ->(_ctx) { [] }) do
        ActiveAdmin.register(Post) do
          graphql do
            capability :editor do
              queries :index
              mutations :create
            end
          end
        end
      end
    end

    it "omits gated query and mutation fields from introspection" do
      data = gql!(<<~GQL)
        {
          queryFields: __type(name: "Query") { fields { name } }
          mutationFields: __type(name: "Mutation") { fields { name } }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      query_fields = data.dig("data", "queryFields", "fields").map { |f| f.fetch("name") }
      expect(query_fields).not_to include("posts")
      expect(query_fields).to include("post")

      mutation_fields = data.dig("data", "mutationFields", "fields").map { |f| f.fetch("name") }
      expect(mutation_fields).not_to include("create_post")
      expect(mutation_fields).to include("update_post")
    end
  end
end
