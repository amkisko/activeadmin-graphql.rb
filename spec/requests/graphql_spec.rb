# frozen_string_literal: true

require_relative "../rails_helper"

module GraphqlSpecRunPayloadFixtures
  UnifiedPayload = Class.new(ActiveAdmin::GraphQL::RunActionPayload) do
    graphql_name "GraphqlSpecUnifiedRunPayload"
    field :kind, ::GraphQL::Types::String, null: true
    define_method(:kind) { "unified" }
  end

  MemberPayload = Class.new(ActiveAdmin::GraphQL::RunActionPayload) do
    graphql_name "GraphqlSpecMemberRunPayload"
    field :note, ::GraphQL::Types::String, null: true
    define_method(:note) { object.ok ? "member" : nil }
  end

  CollectionPayload = Class.new(ActiveAdmin::GraphQL::RunActionPayload) do
    graphql_name "GraphqlSpecCollectionRunPayload"
    field :note, ::GraphQL::Types::String, null: true
    define_method(:note) { object.ok ? "collection" : nil }
  end
end

RSpec.describe "ActiveAdmin GraphQL", type: :request do
  around do |example|
    with_resources_during(example) do
      ActiveAdmin.application.namespaces[:admin].graphql = true
      ActiveAdmin.register(Post) do
        scope :all, default: true
        scope :starred do |posts|
          posts.where(starred: true)
        end
      end
    end
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

  describe "schema introspection" do
    it "returns root types, Query/Mutation fields, and resource types for the namespace schema" do
      data = gql!(<<~GQL)
        {
          __schema {
            queryType { name }
            mutationType { name }
            subscriptionType { name }
          }
          queryFields: __type(name: "Query") { fields(includeDeprecated: true) { name } }
          mutationFields: __type(name: "Mutation") { fields(includeDeprecated: true) { name } }
          postObject: __type(name: "Post") {
            name
            kind
            fields { name }
            interfaces { name }
          }
          resourceIface: __type(name: "ActiveAdminResource") { kind name }
          regUnion: __type(name: "ActiveAdminRegisteredResource") {
            kind
            possibleTypes { name }
          }
          postCreateInput: __type(name: "PostCreateInput") { name kind inputFields { name } }
          runPayload: __type(name: "ActiveAdminRunActionPayload") { name fields { name } }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      d = data.fetch("data")

      schema = d.fetch("__schema")
      expect(schema.dig("queryType", "name")).to eq("Query")
      expect(schema.dig("mutationType", "name")).to eq("Mutation")
      expect(schema["subscriptionType"]).to be_nil

      q_names = d.fetch("queryFields").fetch("fields").map { |f| f.fetch("name") }
      expect(q_names).to include("posts", "post", "registered_resource")

      m_names = d.fetch("mutationFields").fetch("fields").map { |f| f.fetch("name") }
      expect(m_names).to include("create_post", "update_post", "delete_post")
      expect(m_names.any? { |n| n.end_with?("_batch_action") }).to be(true)

      post_t = d.fetch("postObject")
      expect(post_t.fetch("name")).to eq("Post")
      expect(post_t.fetch("kind")).to eq("OBJECT")
      post_field_names = post_t.fetch("fields").map { |f| f.fetch("name") }
      expect(post_field_names).to include("id", "title", "body", "starred")
      expect(post_t.fetch("interfaces").map { |i| i.fetch("name") }).to include("ActiveAdminResource")

      expect(d.fetch("resourceIface").fetch("kind")).to eq("INTERFACE")

      reg_u = d.fetch("regUnion")
      expect(reg_u.fetch("kind")).to eq("UNION")
      expect(reg_u.fetch("possibleTypes").map { |t| t.fetch("name") }).to include("Post")

      pci = d.fetch("postCreateInput")
      expect(pci.fetch("kind")).to eq("INPUT_OBJECT")
      pci_names = pci.fetch("inputFields").map { |f| f.fetch("name") }
      expect(pci_names).to include("title", "body", "starred")

      payload_t = d.fetch("runPayload")
      expect(payload_t.fetch("name")).to eq("ActiveAdminRunActionPayload")
      payload_fields = payload_t.fetch("fields").map { |f| f.fetch("name") }.sort
      expect(payload_fields).to eq(%w[body location ok status])
    end
  end

  context "schema introspection for a resource with full ActiveAdmin surface" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          scope :all, default: true
          scope :starred do |posts|
            posts.where(starred: true)
          end

          batch_action :star_these, confirm: false do |ids|
            batch_action_collection.find(ids).each { |p| p.update!(starred: true) }
            redirect_to collection_path, notice: "Starred"
          end

          member_action :append_title_bang, method: :put do
            resource.update!(title: "#{resource.title}!")
            redirect_to resource_path(resource)
          end

          member_action :append_suffix, method: :put do
            resource.update!(title: "#{resource.title}#{params[:suffix]}")
            redirect_to resource_path(resource)
          end

          collection_action :posts_count, method: :get do
            render json: {count: collection.count}
          end
        end
      end
    end

    it "exposes Query collection and member fields, CRUD mutations, batch, member, and collection action mutations, and run payloads" do
      data = gql!(<<~GQL)
        {
          __schema {
            queryType { name }
            mutationType { name }
            subscriptionType { name }
          }
          queryFields: __type(name: "Query") { fields(includeDeprecated: true) { name } }
          mutationFields: __type(name: "Mutation") { fields(includeDeprecated: true) { name } }
          postObject: __type(name: "Post") { name kind fields { name } }
          runPayload: __type(name: "ActiveAdminRunActionPayload") { name fields { name } }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      d = data.fetch("data")

      schema = d.fetch("__schema")
      expect(schema.dig("queryType", "name")).to eq("Query")
      expect(schema.dig("mutationType", "name")).to eq("Mutation")
      expect(schema["subscriptionType"]).to be_nil

      q_names = d.fetch("queryFields").fetch("fields").map { |f| f.fetch("name") }
      expect(q_names).to include("posts", "post")

      m_names = d.fetch("mutationFields").fetch("fields").map { |f| f.fetch("name") }
      expect(m_names).to include(
        "create_post",
        "update_post",
        "delete_post",
        "posts_batch_action",
        "posts_member_action",
        "posts_member_append_title_bang",
        "posts_member_append_suffix",
        "posts_collection_action",
        "posts_collection_posts_count"
      )

      post_t = d.fetch("postObject")
      expect(post_t.fetch("name")).to eq("Post")
      expect(post_t.fetch("kind")).to eq("OBJECT")
      post_field_names = post_t.fetch("fields").map { |f| f.fetch("name") }
      expect(post_field_names).to include("id", "title", "body", "starred")

      payload_t = d.fetch("runPayload")
      expect(payload_t.fetch("name")).to eq("ActiveAdminRunActionPayload")
      payload_fields = payload_t.fetch("fields").map { |f| f.fetch("name") }.sort
      expect(payload_fields).to eq(%w[body location ok status])
    end
  end

  it "returns not found when the namespace graphql flag is off after routes were loaded" do
    ns = ActiveAdmin.application.namespaces[:admin]
    previous = ns.graphql
    ns.graphql = false
    post "/admin/graphql", params: {query: "{ __typename }"}, as: :json
    expect(response).to have_http_status(:not_found)
  ensure
    ns.graphql = previous
  end

  context "when GraphQL is disabled for a resource" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) { graphql { disable! } }
      end
    end

    it "omits that resource from the schema" do
      data = gql!(<<~GQL)
        {
          queryFields: __type(name: "Query") { fields { name } }
          postType: __type(name: "Post") { name }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      q_names = data.dig("data", "queryFields", "fields").map { |f| f.fetch("name") }
      expect(q_names).not_to include("posts", "post")
      expect(data.dig("data", "postType")).to be_nil
    end
  end

  context "when the authorization adapter denies access to the resource" do
    around do |example|
      ns = ActiveAdmin.application.namespaces[:admin]
      previous = ns.authorization_adapter
      ns.authorization_adapter = ActiveAdmin::GraphQLSpecSupport::DenyPostAuthorizationAdapter
      example.run
    ensure
      ns.authorization_adapter = previous
    end

    it "returns a GraphQL error for list queries" do
      Post.create!(title: "Denied list", body: "z")
      data = gql!(<<~GQL)
        {
          posts(first: 1) {
            edges {
              node {
                id
              }
            }
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_an(Array)
      expect(data.dig("errors", 0, "message")).to include("not authorized")
    end

    it "returns a GraphQL error for singular queries" do
      post = Post.create!(title: "Denied show", body: "z")
      data = gql!(<<~GQL)
        {
          post(id: "#{post.id}") {
            id
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_an(Array)
      expect(data.dig("errors", 0, "message")).to include("not authorized")
    end

    it "returns a GraphQL error for create mutations" do
      data = gql!(<<~GQL)
        mutation {
          create_post(input: { title: "Nope", body: "x" }) {
            id
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_an(Array)
      expect(data.dig("errors", 0, "message")).to include("not authorized")
      expect(Post.find_by(title: "Nope")).to be_nil
    end

    it "returns a GraphQL error for update mutations" do
      post = Post.create!(title: "Before", body: "y")
      data = gql!(<<~GQL)
        mutation {
          update_post(where: { id: "#{post.id}" }, input: { title: "After" }) {
            title
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_an(Array)
      expect(data.dig("errors", 0, "message")).to include("not authorized")
      expect(post.reload.title).to eq("Before")
    end
  end

  context "per-resource graphql DSL (type_name, only, configure)" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          graphql do
            type_name "BlogPost"
            only :title, :body
            configure do
              field :graphql_dsl_echo, GraphQL::Types::String, null: false, camelize: false
              define_method(:graphql_dsl_echo) { "echo" }
            end
          end
          scope :all, default: true
          scope :starred do |posts|
            posts.where(starred: true)
          end
        end
      end
    end

    it "uses the configured GraphQL type name, attribute list, and configure fields" do
      data = gql!(<<~GQL)
        {
          legacyName: __type(name: "Post") { name }
          blogPost: __type(name: "BlogPost") { name fields { name } }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "legacyName")).to be_nil
      expect(data.dig("data", "blogPost", "name")).to eq("BlogPost")
      names = data.dig("data", "blogPost", "fields").map { |f| f.fetch("name") }
      expect(names).to include("id", "title", "body", "graphql_dsl_echo")
      expect(names).not_to include("starred")
    end

    it "resolves configure fields on the object type" do
      post = Post.create!(title: "DSL", body: "b", starred: true)
      data = gql!(<<~GQL)
        {
          post(id: "#{post.id}") {
            graphql_dsl_echo
            title
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "post", "graphql_dsl_echo")).to eq("echo")
      expect(data.dig("data", "post", "title")).to eq("DSL")
    end

    it "does not assign attributes omitted from graphql only via update mutation" do
      post = Post.create!(title: "T0", body: "b0", starred: false)
      data = gql!(<<~GQL)
        mutation {
          update_post(where: { id: "#{post.id}" }, input: { title: "T1" }) {
            title
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      post.reload
      expect(post.title).to eq("T1")
      expect(post.starred).to be(false)
    end
  end

  context "per-resource graphql resolve_* hooks" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          scope :all, default: true
          graphql do
            resolve_index { |proxy:, **| proxy.relation_for_index.where(starred: true) }
            resolve_show { |proxy:, id:, **| proxy.find_member(id)&.then { |p| p.starred? ? p : nil } }
          end
        end
      end
    end

    it "resolve_index narrows the list connection" do
      Post.create!(title: "In", body: "b", starred: true)
      Post.create!(title: "Out", body: "b", starred: false)
      data = gql!(<<~GQL)
        {
          posts {
            edges {
              node {
                title
              }
            }
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      titles = data.dig("data", "posts", "edges").map { |e| e.fetch("node").fetch("title") }
      expect(titles).to contain_exactly("In")
    end

    it "resolve_show can filter which records are visible" do
      starred = Post.create!(title: "S", body: "b", starred: true)
      plain = Post.create!(title: "P", body: "b", starred: false)

      ok = gql!(<<~GQL)
        { post(id: "#{starred.id}") { title } }
      GQL
      expect(ok["errors"]).to be_nil
      expect(ok.dig("data", "post", "title")).to eq("S")

      hidden = gql!(<<~GQL)
        { post(id: "#{plain.id}") { title } }
      GQL
      expect(hidden["errors"]).to be_nil
      expect(hidden.dig("data", "post")).to be_nil
    end
  end

  context "graphql resolve_create hook" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          scope :all, default: true
          graphql do
            resolve_create do |proxy:, attributes:, **|
              r = proxy.build_new(attributes.merge("title" => "#{attributes["title"]}-hook"))
              raise ::GraphQL::ExecutionError, r.errors.full_messages.to_sentence unless r.save

              r
            end
          end
        end
      end
    end

    it "persists using the hook return value" do
      data = gql!(<<~GQL)
        mutation {
          create_post(input: { title: "T", body: "b" }) {
            title
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "create_post", "title")).to eq("T-hook")
    end
  end

  context "custom page graphql_field" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          scope :all, default: true
          scope :starred do |posts|
            posts.where(starred: true)
          end
        end
        ActiveAdmin.register_page "GraphQL Spec Page" do
          graphql_field :graphql_spec_page_metric, GraphQL::Types::Int, null: false do |_user, _ctx|
            42
          end
        end
      end
    end

    it "exposes the field on Query and runs the resolver" do
      data = gql!(<<~GQL)
        {
          queryFields: __type(name: "Query") { fields { name } }
          graphql_spec_page_metric
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      q_names = data.dig("data", "queryFields", "fields").map { |f| f.fetch("name") }
      expect(q_names).to include("graphql_spec_page_metric")
      expect(data.dig("data", "graphql_spec_page_metric")).to eq(42)
    end
  end

  context "when the namespace requires Devise authentication" do
    around do |example|
      ns = ActiveAdmin.application.namespaces[:admin]
      previous_auth = ns.authentication_method
      previous_user = ns.current_user_method
      ns.authentication_method = :authenticate_admin_user!
      ns.current_user_method = :current_admin_user
      example.run
    ensure
      ns.authentication_method = previous_auth
      ns.current_user_method = previous_user
    end

    let(:admin_user) do
      AdminUser.find_or_create_by!(email: "graphql-auth-spec@example.com") do |u|
        u.password = "password123"
        u.password_confirmation = "password123"
      end
    end

    it "returns 401 for schema introspection when not signed in" do
      post "/admin/graphql",
        params: {query: "{ __schema { queryType { name } } }"},
        as: :json

      expect(response).to have_http_status(:unauthorized)
      payload = JSON.parse(response.body)
      expect(payload["error"]).to include("sign in")
      expect(payload["data"]).to be_nil
    end

    it "returns 401 for a multiplex request when not signed in" do
      post "/admin/graphql",
        params: [{query: "{ __typename }"}],
        as: :json

      expect(response).to have_http_status(:unauthorized)
    end

    it "allows schema introspection when signed in" do
      sign_in admin_user, scope: :admin_user

      post "/admin/graphql",
        params: {query: "{ __schema { queryType { name } } }"},
        as: :json

      expect(response).to have_http_status(:ok)
      data = JSON.parse(response.body)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "__schema", "queryType", "name")).to eq("Query")
    end
  end

  it "lists posts through a connection" do
    Post.create!(title: "GraphQL list A", body: "b", starred: false)
    Post.create!(title: "GraphQL list B", body: "c", starred: true)

    data = gql!(<<~GQL)
      {
        posts(first: 10) {
          edges {
            node {
              id
              ... on ActiveAdminResource {
                __typename
              }
              title
            }
          }
        }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    edges = data.dig("data", "posts", "edges")
    expect(edges).to be_an(Array)

    titles = edges.map { |e| e.dig("node", "title") }
    expect(titles).to include("GraphQL list A", "GraphQL list B")
    expect(edges.first.dig("node", "__typename")).to eq("Post")
  end

  it "lists posts using a typed list filter input" do
    Post.create!(title: "FilterInput A", body: "b", starred: false)

    data = gql!(<<~GQL)
      {
        posts(first: 10, filter: { q: { title_cont: "FilterInput" } }) {
          edges {
            node {
              title
            }
          }
        }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    titles = data.dig("data", "posts", "edges").map { |e| e.dig("node", "title") }
    expect(titles).to eq(["FilterInput A"])
  end

  it "fetches a post via registered_resource union + inline fragment" do
    post = Post.create!(title: "Union fetch", body: "z")

    data = gql!(<<~GQL)
      {
        registered_resource(type_name: "Post", id: "#{post.id}") {
          __typename
          ... on Post {
            title
          }
        }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    expect(data.dig("data", "registered_resource", "__typename")).to eq("Post")
    expect(data.dig("data", "registered_resource", "title")).to eq("Union fetch")
  end

  it "loads one post with a typed where input" do
    post = Post.create!(title: "Where input", body: "w")

    data = gql!(<<~GQL)
      {
        post(where: { id: "#{post.id}" }) {
          title
        }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    expect(data.dig("data", "post", "title")).to eq("Where input")
  end

  it "accepts Ransack-style q, matching REST index params" do
    Post.create!(title: "UniqueGraphQLTitle", body: "x")
    Post.create!(title: "Other", body: "y")

    data = gql!(<<~GQL)
      {
        posts(first: 10, q: { title_cont: "UniqueGraphQL" }) {
          edges {
            node {
              title
            }
          }
        }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    titles = data.dig("data", "posts", "edges").map { |e| e.dig("node", "title") }
    expect(titles).to eq(["UniqueGraphQLTitle"])
  end

  it "accepts a menu scope id, matching REST scope" do
    Post.create!(title: "S1", body: "a", starred: true)
    Post.create!(title: "S2", body: "b", starred: false)

    data = gql!(<<~GQL)
      {
        posts(first: 10, scope: "starred") {
          edges {
            node {
              title
              starred
            }
          }
        }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    edges = data.dig("data", "posts", "edges")
    expect(edges.size).to eq(1)
    expect(edges.first.dig("node", "title")).to eq("S1")
  end

  it "fetches a single post by id" do
    post = Post.create!(title: "One Post", body: "body")

    data = gql!(<<~GQL)
      {
        post(id: "#{post.id}") {
          id
          title
        }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    expect(data.dig("data", "post", "title")).to eq("One Post")
  end

  it "creates a post via mutation" do
    data = gql!(<<~GQL)
      mutation {
        create_post(input: { title: "Created via GQL", body: "hello" }) {
          id
          title
          body
        }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    expect(data.dig("data", "create_post", "title")).to eq("Created via GQL")
    expect(Post.find_by(title: "Created via GQL")).to be_present
  end

  it "updates a post via mutation" do
    post = Post.create!(title: "Before", body: "x")

    data = gql!(<<~GQL)
      mutation {
        update_post(where: { id: "#{post.id}" }, input: { title: "After" }) {
          title
        }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    expect(data.dig("data", "update_post", "title")).to eq("After")
    expect(post.reload.title).to eq("After")
  end

  it "deletes a post via mutation" do
    post = Post.create!(title: "Delete me", body: "x")

    data = gql!(<<~GQL)
      mutation {
        delete_post(where: { id: "#{post.id}" })
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    expect(data.dig("data", "delete_post")).to be(true)
    expect(Post.find_by(id: post.id)).to be_nil
  end

  it "runs a multiplexed request when given a JSON array" do
    payload = [
      {query: "query A { __typename }"},
      {query: "query B { __typename }"}
    ]

    post "/admin/graphql", params: payload, as: :json

    expect(response).to have_http_status(:ok)
    results = JSON.parse(response.body)
    expect(results).to be_an(Array)
    expect(results.size).to eq(2)
    expect(results.first.dig("data", "__typename")).to eq("Query")
    expect(results.second.dig("data", "__typename")).to eq("Query")
  end

  context "nested resource (belongs_to)" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(User)
        ActiveAdmin.register(Post) { belongs_to :author, class_name: "User", param: "user_id", optional: true }
      end
    end

    it "scopes posts to the parent user when user_id is given" do
      u1 = User.create!(first_name: "A", last_name: "One")
      u2 = User.create!(first_name: "B", last_name: "Two")
      Post.create!(title: "P1", body: "a", author: u1)
      Post.create!(title: "P2", body: "b", author: u2)

      data = gql!(<<~GQL)
        {
          posts(first: 10, user_id: "#{u1.id}") {
            edges {
              node {
                title
              }
            }
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      titles = data.dig("data", "posts", "edges").map { |e| e.dig("node", "title") }
      expect(titles).to eq(["P1"])
    end

    it "creates a post under the parent via mutation" do
      u = User.create!(first_name: "Parent", last_name: "User")

      data = gql!(<<~GQL)
        mutation {
          create_post(input: { user_id: "#{u.id}", title: "Nested create", body: "nb" }) {
            title
            author_id
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      rec = Post.find_by(title: "Nested create")
      expect(rec).to be_present
      expect(rec.author_id).to eq(u.id)
    end
  end

  context "batch, member, and collection actions (controller parity)" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          batch_action :star_these, confirm: false do |ids|
            batch_action_collection.find(ids).each { |p| p.update!(starred: true) }
            redirect_to collection_path, notice: "Starred"
          end

          member_action :append_title_bang, method: :put do
            resource.update!(title: "#{resource.title}!")
            redirect_to resource_path(resource)
          end

          member_action :append_suffix, method: :put do
            resource.update!(title: "#{resource.title}#{params[:suffix]}")
            redirect_to resource_path(resource)
          end

          collection_action :posts_count, method: :get do
            render json: {count: collection.count}
          end
        end
      end
    end

    it "runs a batch action by name" do
      a = Post.create!(title: "Batch A", body: "x", starred: false)
      b = Post.create!(title: "Batch B", body: "y", starred: false)

      data = gql!(<<~GQL)
        mutation {
          posts_batch_action(batch_action: "star_these", ids: ["#{a.id}", "#{b.id}"]) {
            ok
            status
            location
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "posts_batch_action", "ok")).to be(true)
      expect(a.reload.starred).to be(true)
      expect(b.reload.starred).to be(true)
    end

    it "runs a member action by name" do
      post = Post.create!(title: "Flat", body: "z")

      data = gql!(<<~GQL)
        mutation {
          posts_member_action(action: "append_title_bang", id: "#{post.id}") {
            ok
            location
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "posts_member_action", "ok")).to be(true)
      expect(post.reload.title).to eq("Flat!")
    end

    it "passes structured key/value params to member actions" do
      post = Post.create!(title: "Hi", body: "z")

      data = gql!(<<~GQL)
        mutation {
          posts_member_action(
            action: "append_suffix",
            id: "#{post.id}",
            params: [{ key: "suffix", value: "__end" }]
          ) {
            ok
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "posts_member_action", "ok")).to be(true)
      expect(post.reload.title).to eq("Hi__end")
    end

    it "runs per-action member field with the same behavior as the aggregate mutation" do
      post = Post.create!(title: "ByField", body: "z")

      data = gql!(<<~GQL)
        mutation {
          posts_member_append_suffix(id: "#{post.id}", params: [{ key: "suffix", value: "!" }]) {
            ok
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "posts_member_append_suffix", "ok")).to be(true)
      expect(post.reload.title).to eq("ByField!")
    end

    it "runs a collection action by name" do
      Post.create!(title: "C1", body: "a")
      Post.create!(title: "C2", body: "b")

      data = gql!(<<~GQL)
        mutation {
          posts_collection_action(action: "posts_count") {
            ok
            body
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      payload = data.dig("data", "posts_collection_action")
      expect(payload["ok"]).to be(true)
      expect(JSON.parse(payload["body"])["count"]).to eq(2)
    end
  end

  context "per-action member field with typed GraphQL arguments" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          graphql do
            member_action_mutation(:append_suffix) do
              arguments do
                argument :suffix, GraphQL::Types::String, required: true, camelize: false
              end
            end
          end
          member_action :append_suffix, method: :put do
            resource.update!(title: "#{resource.title}#{params[:suffix]}")
            redirect_to resource_path(resource)
          end
        end
      end
    end

    it "maps extra field arguments onto controller params" do
      post = Post.create!(title: "Arg", body: "z")
      data = gql!(<<~GQL)
        mutation {
          posts_member_append_suffix(id: "#{post.id}", suffix: "_typed") {
            ok
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "posts_member_append_suffix", "ok")).to be(true)
      expect(post.reload.title).to eq("Arg_typed")
    end
  end

  context "graphql run_action_payload_type overrides" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          graphql do
            run_action_payload_type GraphqlSpecRunPayloadFixtures::UnifiedPayload
          end
          batch_action :star_these, confirm: false do |ids|
            batch_action_collection.find(ids).each { |p| p.update!(starred: true) }
          end
          member_action :append_title_bang, method: :put do
            resource.update!(title: "#{resource.title}!")
            redirect_to resource_path(resource)
          end
          collection_action :posts_count, method: :get do
            render json: {count: collection.count}
          end
        end
      end
    end

    it "uses the configured type for all run-action mutations" do
      data = gql!(<<~GQL)
        query {
          m: __type(name: "Mutation") {
            fields(includeDeprecated: true) {
              name
              type { kind name ofType { kind name ofType { kind name } } }
            }
          }
        }
      GQL

      fields = data.dig("data", "m", "fields")
      %w[
        posts_batch_action
        posts_member_action
        posts_member_append_title_bang
        posts_collection_action
        posts_collection_posts_count
      ].each do |fname|
        row = fields.find { |f| f.fetch("name") == fname }
        expect(graphql_type_unwrap_name(row.fetch("type"))).to eq("GraphqlSpecUnifiedRunPayload")
      end
    end

    it "returns extra fields from the custom payload type" do
      post = Post.create!(title: "K", body: "z")
      data = gql!(<<~GQL)
        mutation {
          posts_member_action(action: "append_title_bang", id: "#{post.id}") {
            ok
            kind
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "posts_member_action", "kind")).to eq("unified")
    end
  end

  context "per-kind run_action payload types (member vs collection)" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post) do
          graphql do
            member_action_mutation do
              type GraphqlSpecRunPayloadFixtures::MemberPayload
            end
            collection_action_mutation do
              type GraphqlSpecRunPayloadFixtures::CollectionPayload
            end
          end
          batch_action :star_these, confirm: false do |ids|
            batch_action_collection.find(ids).each { |p| p.update!(starred: true) }
          end
          member_action :append_title_bang, method: :put do
            resource.update!(title: "#{resource.title}!")
            redirect_to resource_path(resource)
          end
          collection_action :posts_count, method: :get do
            render json: {count: collection.count}
          end
        end
      end
    end

    it "resolves different GraphQL types per action kind" do
      data = gql!(<<~GQL)
        query {
          m: __type(name: "Mutation") {
            fields(includeDeprecated: true) {
              name
              type { kind name ofType { kind name } }
            }
          }
        }
      GQL

      fields = data.dig("data", "m", "fields")
      batch_t = graphql_type_unwrap_name(fields.find { |f| f.fetch("name") == "posts_batch_action" }.fetch("type"))
      member_t = graphql_type_unwrap_name(fields.find { |f| f.fetch("name") == "posts_member_action" }.fetch("type"))
      member_named_t = graphql_type_unwrap_name(fields.find { |f| f.fetch("name") == "posts_member_append_title_bang" }.fetch("type"))
      coll_t = graphql_type_unwrap_name(fields.find { |f| f.fetch("name") == "posts_collection_action" }.fetch("type"))
      coll_named_t = graphql_type_unwrap_name(fields.find { |f| f.fetch("name") == "posts_collection_posts_count" }.fetch("type"))
      expect(batch_t).to eq("ActiveAdminRunActionPayload")
      expect(member_t).to eq("GraphqlSpecMemberRunPayload")
      expect(member_named_t).to eq("GraphqlSpecMemberRunPayload")
      expect(coll_t).to eq("GraphqlSpecCollectionRunPayload")
      expect(coll_named_t).to eq("GraphqlSpecCollectionRunPayload")
    end

    it "exposes per-kind payload fields in mutations" do
      post = Post.create!(title: "M", body: "z")
      m_data = gql!(<<~GQL)
        mutation {
          posts_member_append_title_bang(id: "#{post.id}") {
            ok
            note
          }
        }
      GQL
      expect(m_data["errors"]).to be_nil
      expect(m_data.dig("data", "posts_member_append_title_bang", "note")).to eq("member")

      Post.create!(title: "C", body: "a")
      c_data = gql!(<<~GQL)
        mutation {
          posts_collection_posts_count {
            ok
            note
          }
        }
      GQL
      expect(c_data["errors"]).to be_nil
      expect(c_data.dig("data", "posts_collection_posts_count", "note")).to eq("collection")
    end
  end

  context "when graphql_visibility and graphql_schema_visible hide Post" do
    around do |example|
      ns = ActiveAdmin.application.namespaces[:admin]
      previous_visibility = ns.graphql_visibility
      previous_hook = ns.graphql_schema_visible
      ns.graphql_visibility = {preload: false}
      ns.graphql_schema_visible = ->(_ctx, meta) { meta[:graphql_type_name] != "Post" }
      ActiveAdmin::GraphQL.clear_schema_cache!
      begin
        with_resources_during(example) do
          ns.graphql = true
          ActiveAdmin.register(Post) { scope :all, default: true }
        end
      ensure
        ns.graphql_visibility = previous_visibility
        ns.graphql_schema_visible = previous_hook
        ActiveAdmin::GraphQL.clear_schema_cache!
      end
    end

    it "omits Post and its query fields from introspection and rejects posts queries" do
      data = gql!(<<~GQL)
        {
          postType: __type(name: "Post") { name }
          queryFields: __type(name: "Query") { fields { name } }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "postType")).to be_nil
      qnames = data.dig("data", "queryFields", "fields").map { |f| f.fetch("name") }
      expect(qnames).not_to include("posts", "post")

      err = gql!(<<~GQL)
        { posts(first: 1) { edges { node { id } } } }
      GQL
      expect(err["errors"]).to be_an(Array)
      messages = err["errors"].map { |e| e.fetch("message") }
      expect(messages.join).to match(/posts|Field|undefined/i)
    end
  end

  context "composite primary key (LibraryEdition)" do
    around do |example|
      ActiveAdmin::GraphQL.clear_schema_cache!
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(LibraryEdition) do
          permit_params :book_code, :seq, :label
        end
      end
      ActiveAdmin::GraphQL.clear_schema_cache!
    end

    let(:edition) { LibraryEdition.create!(book_code: "CPK", seq: 7, label: "Vol") }
    let(:graphql_id) { ActiveAdmin::PrimaryKey.graphql_id_value(edition) }

    it "lists editions with a JSON id field" do
      edition
      data = gql!(<<~GQL)
        {
          library_editions(first: 5) {
            edges { node { id label } }
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      edges = data.dig("data", "library_editions", "edges")
      expect(edges.size).to eq(1)
      expect(edges[0].dig("node", "id")).to eq(graphql_id)
      expect(edges[0].dig("node", "label")).to eq("Vol")
    end

    it "loads one edition by JSON id on the field and in where input" do
      edition
      escaped = graphql_id.gsub('"', '\\"')
      data = gql!(<<~GQL)
        {
          a: libraryEdition(id: "#{escaped}") { label book_code seq }
          b: libraryEdition(where: { id: "#{escaped}" }) { label }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "a", "label")).to eq("Vol")
      expect(data.dig("data", "a", "book_code")).to eq("CPK")
      expect(data.dig("data", "a", "seq")).to eq(7)
      expect(data.dig("data", "b", "label")).to eq("Vol")
    end

    it "loads one edition by primary-key columns on the field" do
      edition
      data = gql!(<<~GQL)
        {
          libraryEdition(book_code: "CPK", seq: 7) {
            id
            label
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "libraryEdition", "id")).to eq(graphql_id)
    end

    it "loads via where input with discrete keys" do
      edition
      data = gql!(<<~GQL)
        {
          libraryEdition(where: { book_code: "CPK", seq: 7 }) {
            label
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "libraryEdition", "label")).to eq("Vol")
    end

    it "updates via where with composite columns" do
      edition
      data = gql!(<<~GQL)
        mutation {
          update_library_edition(where: { book_code: "CPK", seq: 7 }, input: { label: "V2" }) {
            label
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "update_library_edition", "label")).to eq("V2")
      expect(edition.reload.label).to eq("V2")
    end

    it "creates an edition with composite keys in the input" do
      data = gql!(<<~GQL)
        mutation {
          create_library_edition(input: { book_code: "NEW", seq: 9, label: "Fresh" }) {
            id
            label
          }
        }
      GQL

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "create_library_edition", "label")).to eq("Fresh")
      row = LibraryEdition.find_by(book_code: "NEW", seq: 9)
      expect(row).to be_present
      expect(row.label).to eq("Fresh")
    end

    it "registered_resource accepts the same JSON id" do
      edition
      data = gql!(
        <<~GQL,
          query($id: ID!, $tn: String!) {
            registered_resource(type_name: $tn, id: $id) {
              ... on LibraryEdition { label }
            }
          }
        GQL
        {"id" => graphql_id, "tn" => "LibraryEdition"}
      )

      expect(response).to have_http_status(:ok)
      expect(data["errors"]).to be_nil
      expect(data.dig("data", "registered_resource", "label")).to eq("Vol")
    end
  end
end
