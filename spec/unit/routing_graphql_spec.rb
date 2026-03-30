# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "GraphQL routing", type: :routing do
  let(:namespaces) { ActiveAdmin.application.namespaces }

  describe "graphql endpoint" do
    around do |example|
      with_resources_during(example) do
        ActiveAdmin.application.namespaces[:admin].graphql = true
        ActiveAdmin.register(Post)
      end
    end

    it "routes POST /admin/graphql to ActiveAdmin::GraphqlController with namespace default" do
      expect(post: "/admin/graphql").to route_to(
        controller: "active_admin/graphql",
        action: "execute",
        active_admin_namespace: :admin
      )
    end
  end
end
