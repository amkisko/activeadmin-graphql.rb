# frozen_string_literal: true

module GraphQLCapabilitiesRequestHelper
  def gql!(query)
    post "/admin/graphql", params: {query: query}, as: :json
    JSON.parse(response.body)
  end

  def with_capabilities(
    example,
    capabilities_proc:,
    visibility: {preload: false},
    visibility_profile: nil
  )
    ns = ActiveAdmin.application.namespaces[:admin]
    previous_capabilities = ns.graphql_capabilities
    previous_visibility = ns.graphql_visibility
    previous_profile = ns.graphql_visibility_profile
    ns.graphql_capabilities = capabilities_proc
    ns.graphql_visibility = visibility
    ns.graphql_visibility_profile = visibility_profile
    ActiveAdmin::GraphQL.clear_schema_cache!
    with_resources_during(example) do
      ns.graphql = true
      yield
    end
    ActiveAdmin::GraphQL.clear_schema_cache!
  ensure
    ns.graphql_capabilities = previous_capabilities
    ns.graphql_visibility = previous_visibility
    ns.graphql_visibility_profile = previous_profile
  end
end
