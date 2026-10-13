# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "ActiveAdmin GraphQL member action dry_run", type: :request do
  def gql!(query)
    post "/admin/graphql", params: {query: query}, as: :json
    JSON.parse(response.body)
  end

  around do |example|
    with_resources_during(example) do
      ActiveAdmin.application.namespaces[:admin].graphql = true
      ActiveAdmin.register(Post) do
        member_action :graphql_publish, method: :put do
          resource.update!(starred: true)
          head :ok
        end
        graphql do
          member_action_mutation :graphql_publish, dry_run: true do
            preview do |record, **|
              if record&.title.to_s.start_with?("ok")
                ok("would_run:graphql_publish:#{record.id}")
              else
                refuse("not_publishable")
              end
            end
          end
        end
      end
    end
  end

  it "returns preview without running the action when dry_run is true" do
    blog_post = Post.create!(title: "ok-one", body: "b", starred: false)
    data = gql!(<<~GQL)
      mutation {
        posts_member_graphql_publish(id: "#{blog_post.id}", dry_run: true) {
          ok
          body
        }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    expect(data.dig("data", "posts_member_graphql_publish", "ok")).to be(true)
    expect(data.dig("data", "posts_member_graphql_publish", "body")).to eq(
      "would_run:graphql_publish:#{blog_post.id}"
    )
    expect(blog_post.reload.starred).to be(false)
  end

  it "refuses without running when preview refuses" do
    blog_post = Post.create!(title: "blocked", body: "b", starred: false)
    data = gql!(<<~GQL)
      mutation {
        posts_member_graphql_publish(id: "#{blog_post.id}", dry_run: false) {
          ok
          body
          status
        }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    expect(data.dig("data", "posts_member_graphql_publish", "ok")).to be(false)
    expect(data.dig("data", "posts_member_graphql_publish", "body")).to eq("not_publishable")
    expect(blog_post.reload.starred).to be(false)
  end

  it "runs the member action when preview allows and dry_run is false" do
    blog_post = Post.create!(title: "ok-two", body: "b", starred: false)
    data = gql!(<<~GQL)
      mutation {
        posts_member_graphql_publish(id: "#{blog_post.id}") {
          ok
          status
        }
      }
    GQL

    expect(response).to have_http_status(:ok)
    expect(data["errors"]).to be_nil
    expect(data.dig("data", "posts_member_graphql_publish", "ok")).to be(true)
    expect(blog_post.reload.starred).to be(true)
  end
end
