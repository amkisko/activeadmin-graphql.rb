# RFC 0004: Schema and resource DSL

- Feature Name: schema-and-dsl
- Type: Standards Track
- Status: Stable
- Created: 2026-08-18
- Author: Andrei Makarov
- Relates: RFC 0002, RFC 0003, RFC 0005

## Summary

The GraphQL schema is generated from ActiveAdmin registration. Optional `graphql do ... end` on a resource customizes fields without a parallel registry. Pages may declare `graphql_field`.

## Motivation

A standalone graphql-ruby schema beside ActiveAdmin lets API and admin diverge on day two. Field names, enum type names, and mutation input shapes are the client contract.

## Guide-level explanation

Bundling the gem loads `activeadmin/graphql` and calls `ActiveAdmin::GraphQL.load!`. The schema class for a namespace is built on demand via `ActiveAdmin::GraphQL.schema_for(namespace)`.

Inside `ActiveAdmin.register`, optional `graphql do ... end` sets resolver overrides. Custom pages use `graphql_field(field_name, graphql_type, null:, description:)`.

The generated schema mirrors HTML and JSON admin surfaces: CRUD, batch actions, member and collection actions, nested `belongs_to` parents.

## Reference-level explanation

Field names stay owned by schema construction even when the DSL supplies resolvers. Authorization and filters are RFC 0005. HTTP mount is RFC 0003.

## Registrar

DSL: `graphql`, `graphql_field`. Entry: `ActiveAdmin::GraphQL.schema_for`.

## Drawbacks

Generated names couple clients to ActiveAdmin resource names. DSL overrides cannot silently rename fields the schema already claimed.

## Rationale and alternatives

A hand-written schema would let API and admin diverge. Generating from HTML only would drop JSON batch actions. Doing nothing leaves two registries.

## Prior art

graphql-ruby schema classes. ActiveAdmin resource DSL. GraphQL::Batch and similar schema generators from ORMs. RFC 0002 records one client-migration note for older enum and input shapes as evidence that names are the contract.

## Unresolved questions

Whether the GraphQL schema layout should split from the HTTP endpoint into further RFCs per type family.
