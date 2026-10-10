# GraphQL Federation support

## Participants

Andrei Makarov

## Decisions

activeadmin-graphql does not implement GraphQL Federation (Apollo Federation
v1/v2, subgraph/supergraph, `@key` entities, `_entities` / `_service`). The
product is one graphql-ruby schema per ActiveAdmin namespace for that admin
HTTP endpoint.

RFC 0007 `graphql { identity ... }` and `ActiveAdminResource.id` are record
lookup identity inside that schema. They are not federation entity keys and
do not emit federation SDL directives.

## Effects

Searched lib, docs, rfcs, spec, and the gemspec for federation, subgraph,
supergraph, Apollo, `@key`, shareable, apollo-federation, `_entities`, and
`_service`. No product hits.

Runtime dependencies are `activeadmin` and `graphql` only. Schema build is
`Class.new(::GraphQL::Schema)` with query, mutation, dataloader, and optional
visibility (`lib/active_admin/graphql/schema_builder/build.rb`).
`ResourceInterface` is a local interface for fragment reuse, not a federation
entity type.

An app could in principle call `graphql_configure_schema` on the built schema
and layer a federation library itself. That path is neither documented nor
tested here.

## Next

Keep federation out of scope until a host names a concrete subgraph contract
and an RFC. Prefer documenting “single-schema admin API; federation
unsupported” if readers keep asking.

## Source

activeadmin-graphql.gemspec
lib/active_admin/graphql/schema_builder/build.rb
lib/active_admin/graphql/resource_interface.rb
rfcs/0007-graphql-identity.md
docs/issues/20261010111300_partitions-and-shards-support.md
