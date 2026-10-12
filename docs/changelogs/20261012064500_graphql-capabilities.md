# GraphQL capabilities

## Participants

Andrei Makarov

## Decisions

Add RFC 0008 capability grants. Resource DSL `capability` associates many
object fields, queries, and mutations with one name. Namespace
`graphql_capabilities` fills `context[:capabilities]` per request. SchemaField
checks capability in `visible?` and `authorized?`. Capabilities do not replace
ActiveAdmin authorization. Subscriptions stay out of scope.

## Effects

Gated members fail closed without the grant. With `graphql_visibility`,
introspection omits them. Aggregate run-action resolvers also check
per-action capability keys (`member_*`, `batch_*`, `collection_*`).
`belongs_to` association fields honor `fields:` capabilities. Schema build
rejects unknown capability field names and rejects named visibility profiles
combined with `graphql_capabilities` (dynamic visibility required).

## Next

Policy payloads listing field capabilities. Mutation input attribute maps.
Transport gates if subscriptions ship later.

## Source

RFC 0008. docs/graphql-api.md. spec/unit/capability_spec.rb,
spec/unit/capability_dsl_spec.rb, spec/requests/graphql_capabilities_spec.rb,
spec/requests/graphql_capabilities_edge_spec.rb.
