# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe "ActiveAdmin GraphQL run-action capability defaults", type: :request do
  include GraphQLCapabilitiesRequestHelper

  def mutation_field_names
    data = gql!(<<~GQL)
      { mutationFields: __type(name: "Mutation") { fields { name } } }
    GQL
    expect(response).to have_http_status(:ok)
    data.dig("data", "mutationFields", "fields").map { |f| f.fetch("name") }
  end

  context "when member action default is set" do
    around do |example|
      ns = ActiveAdmin.application.namespaces[:admin]
      previous_default = ns.graphql_member_action_capability_default
      ns.graphql_member_action_capability_default = :support_act
      with_capabilities(example, capabilities_proc: ->(_ctx) { [] }) do
        ActiveAdmin.register(Post) do
          member_action :graphql_noop, method: :put do
            head :ok
          end
          graphql do
            member_action_mutation :graphql_noop do
              authorize false
              resolve do |**|
                ActiveAdmin::GraphQL::RunActionPayload::Result.new(
                  ok: true, status: 200, location: nil, body: nil
                )
              end
            end
          end
        end
      end
    ensure
      ns.graphql_member_action_capability_default = previous_default
    end

    it "omits member action mutations when the default capability is missing" do
      expect(mutation_field_names).not_to include("posts_member_graphql_noop")
    end
  end

  context "when batch action default is set" do
    around do |example|
      ns = ActiveAdmin.application.namespaces[:admin]
      previous_default = ns.graphql_batch_action_capability_default
      ns.graphql_batch_action_capability_default = :support_act
      with_capabilities(example, capabilities_proc: ->(_ctx) { [] }) do
        ActiveAdmin.register(Post) do
          batch_action :star_these, confirm: false do |ids|
            batch_action_collection.find(ids).each { |p| p.update!(starred: true) }
          end
        end
      end
    ensure
      ns.graphql_batch_action_capability_default = previous_default
    end

    it "omits the batch action mutation when the default capability is missing" do
      expect(mutation_field_names).not_to include("posts_batch_action")
    end
  end

  context "when collection action default is set" do
    around do |example|
      ns = ActiveAdmin.application.namespaces[:admin]
      previous_default = ns.graphql_collection_action_capability_default
      ns.graphql_collection_action_capability_default = :support_act
      with_capabilities(example, capabilities_proc: ->(_ctx) { [] }) do
        ActiveAdmin.register(Post) do
          collection_action :posts_count, method: :get do
            render json: {count: collection.count}
          end
        end
      end
    ensure
      ns.graphql_collection_action_capability_default = previous_default
    end

    it "omits collection action mutations when the default capability is missing" do
      names = mutation_field_names
      expect(names).not_to include("posts_collection_action")
      expect(names).not_to include("posts_collection_posts_count")
    end
  end
end
