# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "ActiveAdmin GraphQL mutation permit_params", type: :request do
  def gql!(query, variables = nil)
    body = {query: query}
    body[:variables] = variables if variables
    post "/admin/graphql", params: body, as: :json
    JSON.parse(response.body)
  end

  def type_field_names(type_name, fields_key)
    data = gql!(%({ __type(name: "#{type_name}") { #{fields_key} { name } } }))
    expect(data["errors"]).to be_nil
    data.dig("data", "__type", fields_key).to_a.map { |field| field.fetch("name") }
  end

  context "default generated inputs" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post)
      end
    end

    it "omits timestamps from mutation inputs and keeps them on the object type" do
      create_names = type_field_names("PostCreateInput", "inputFields")
      update_names = type_field_names("PostUpdateInput", "inputFields")
      expect(create_names).to include("title", "body", "starred")
      expect(create_names).not_to include("created_at", "updated_at")
      expect(update_names).not_to include("created_at", "updated_at")
      expect(type_field_names("Post", "fields")).to include("starred", "created_at", "updated_at")
    end

    it "rejects a client-supplied created_at on create" do
      data = gql!(<<~GQL)
        mutation {
          create_post(input: { title: "Stamp", body: "b", created_at: "2020-01-02T03:04:05Z" }) {
            title
          }
        }
      GQL

      expect(data["errors"]).to be_an(Array)
      expect(data.dig("errors", 0, "message")).to include("created_at")
      expect(Post.find_by(title: "Stamp")).to be_nil
    end
  end

  context "shared permit_params" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          graphql do
            permit_params :title, :body
          end
        end
      end
    end

    it "keeps other columns on the object type and omits them from mutation inputs" do
      expect(type_field_names("Post", "fields")).to include("starred", "created_at", "updated_at")
      expect(type_field_names("PostCreateInput", "inputFields")).to contain_exactly("title", "body")
      expect(type_field_names("PostUpdateInput", "inputFields")).to contain_exactly("title", "body")
    end

    it "rejects a create input field outside permit_params" do
      data = gql!(<<~GQL)
        mutation {
          create_post(input: { title: "Nope", body: "b", starred: true }) { id }
        }
      GQL

      expect(data["errors"]).to be_an(Array)
      expect(data.dig("errors", 0, "message")).to include("starred")
      expect(Post.find_by(title: "Nope")).to be_nil
    end
  end

  context "nested create and update permit_params" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          graphql do
            create do
              permit_params :title, :body, :starred
            end
            update do
              permit_params :title, :body
            end
          end
        end
      end
    end

    it "allows starred on create and not on update while keeping it readable" do
      expect(type_field_names("Post", "fields")).to include("starred")
      expect(type_field_names("PostCreateInput", "inputFields")).to include("starred")
      expect(type_field_names("PostUpdateInput", "inputFields")).not_to include("starred")

      created = gql!(<<~GQL)
        mutation {
          create_post(input: { title: "Star", body: "b", starred: true }) { id starred }
        }
      GQL
      expect(created["errors"]).to be_nil
      post_id = created.dig("data", "create_post", "id")
      expect(created.dig("data", "create_post", "starred")).to be(true)

      updated = gql!(<<~GQL)
        mutation {
          update_post(where: { id: "#{post_id}" }, input: { title: "Star2", starred: false }) { title }
        }
      GQL
      expect(updated["errors"]).to be_an(Array)
      expect(updated.dig("errors", 0, "message")).to include("starred")
      expect(Post.find(post_id).starred).to be(true)
    end
  end

  context "permit_params cannot widen past graphql only" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          graphql do
            only :title, :body
            create do
              permit_params :title, :body, :starred
            end
          end
        end
      end
    end

    it "omits starred from queries and create input" do
      expect(type_field_names("Post", "fields")).not_to include("starred")
      expect(type_field_names("PostCreateInput", "inputFields")).to contain_exactly("title", "body")
    end
  end

  context "empty permit_params" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          graphql do
            permit_params
          end
        end
      end
    end

    it "builds create and update inputs with no column arguments" do
      expect(type_field_names("PostCreateInput", "inputFields")).to eq([])
      expect(type_field_names("PostUpdateInput", "inputFields")).to eq([])
    end
  end

  context "create resolve paired with permit_params" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          graphql do
            create do
              permit_params :title, :body
              resolve do |proxy:, attributes:, **|
                record = proxy.build_new(attributes.merge("starred" => true))
                unless record.save
                  raise ::GraphQL::ExecutionError, record.errors.full_messages.to_sentence
                end
                record
              end
            end
          end
        end
      end
    end

    it "lets the create resolve hook set starred through ResourceQueryProxy#build_new" do
      data = gql!(<<~GQL)
        mutation {
          create_post(input: { title: "Hook", body: "b" }) { starred }
        }
      GQL

      expect(data["errors"]).to be_nil
      expect(data.dig("data", "create_post", "starred")).to be(true)
      expect(Post.find_by!(title: "Hook").starred).to be(true)
    end
  end

  context "HTML permit_params seeds GraphQL when graphql permit_params is unset" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          permit_params :title, :body
        end
      end
    end

    it "uses the HTML allowlist for both mutation inputs" do
      expect(type_field_names("Post", "fields")).to include("starred")
      expect(type_field_names("PostCreateInput", "inputFields")).to contain_exactly("title", "body")
      expect(type_field_names("PostUpdateInput", "inputFields")).to contain_exactly("title", "body")
    end
  end

  context "explicit graphql permit_params can include timestamps" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          graphql do
            permit_params :title, :body, :created_at
          end
        end
      end
    end

    it "persists created_at when listed on graphql permit_params" do
      expect(type_field_names("PostCreateInput", "inputFields")).to include("created_at")
      data = gql!(<<~GQL)
        mutation {
          create_post(input: { title: "Stamp", body: "b", created_at: "2020-01-02T03:04:05Z" }) {
            created_at
          }
        }
      GQL

      expect(data["errors"]).to be_nil
      expect(data.dig("data", "create_post", "created_at")).to eq("2020-01-02T03:04:05Z")
    end
  end

  context "graphql_name alias" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          graphql do
            graphql_name "NamedPost"
          end
        end
      end
    end

    it "sets the GraphQL type basename like type_name" do
      expect(gql!(%({ __type(name: "NamedPost") { name } })).dig("data", "__type", "name")).to eq("NamedPost")
      expect(gql!(%({ __type(name: "Post") { name } })).dig("data", "__type")).to be_nil
    end
  end

  context "destroy mutation alias" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post)
      end
    end

    it "destroys a record through destroy_post and keeps delete_post" do
      post = Post.create!(title: "Gone", body: "x")
      data = gql!(<<~GQL)
        mutation {
          destroy_post(where: { id: "#{post.id}" })
        }
      GQL

      expect(data["errors"]).to be_nil
      expect(data.dig("data", "destroy_post")).to be(true)
      expect(Post.find_by(id: post.id)).to be_nil
      names = gql!(%({ mutationFields: __type(name: "Mutation") { fields { name } } }))
        .dig("data", "mutationFields", "fields").map { |field| field.fetch("name") }
      expect(names).to include("delete_post", "destroy_post")
    end
  end
end
