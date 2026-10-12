# GraphQL surface toggles

## Participants

Andrei Makarov

## Decisions

Add namespace and per-resource controls for schema surfaces that were always on
once a resource was enabled. Defaults stay `true` so 0.3.x behavior is
unchanged.

Namespace-only switches: `graphql_registered_resource_enabled`,
`graphql_belongs_to_associations_enabled`, `graphql_policies_enabled`.
Policy payloads use `graphql_policy_adapter` (default `PolicyAdapter`).
Per-resource policy seed is `graphql_policies_enabled_default`.

Per-resource seeds from namespace defaults: queries, mutations (CRUD),
run-actions, and policies. Resource DSL exposes matching `enable_*!` /
`disable_*!` methods. `queries_enabled` also gates `registered_resource`
membership. Schema build raises if `Query` would have no fields.

## Effects

Schema builder skips policy query fields, registered_resource union, belongs_to
wiring, list/show fields, CRUD mutations, and run-action mutations when the
matching flag is off. Request specs cover the new settings and DSL, including
empty-Query rejection and registered_resource gating by queries.

## Next

Consumers that want a narrow support-style API can combine
`graphql_resource_enabled_default = false` with policies / registered_resource /
belongs_to off, then enable only the surfaces each resource needs.

## Source

CHANGELOG Unreleased. docs/graphql-api.md.
spec/requests/graphql_surface_toggles_spec.rb.
spec/requests/graphql_policy_surface_spec.rb.
spec/requests/graphql_query_surface_contract_spec.rb.
