# Table partitions and database shards support

## Participants

Andrei Makarov

## Decisions

activeadmin-graphql does not treat database table partitions or Rails
database shards as a GraphQL configuration surface. Identity DSL (RFC 0007)
and ActiveRecord composite primary keys only encode lookup columns into
GraphQL `id`. They do not select a shard, connection role, or physical
partition.

App-level Rails multi-database setup (`connects_to`, `connected_to`,
horizontal shards, tenant middleware) may still apply implicitly: GraphQL
resolvers reuse ActiveAdmin `scoped_collection` / `find_resource` on whatever
connection the request process already has. That inheritance is undocumented
as a product feature and untested in this gem.

## Effects

Searched lib, docs, rfcs, and spec for partition, shard, connects_to,
multiple database, tenant routing, writing_role, and reading_role.

Product code has no shard or partition API. Hits for “shard” and “partition”
are Polyrun/CI test parallelism and agent IO-fault vocabulary, not databases.

Dummy app uses one SQLite database (`spec/dummy/config/database.yml`). No
multi-DB, no partitioned table fixtures, no `connected_to` specs.

`RecordSource`, `PrimaryKey`, and `ResourceIdentity` run `where` / encode on
the current model class only. A partition-key column can appear in
`graphql { identity ... }` as part of the id string; that still queries the
already-selected connection and does not prune or route partitions.

## Next

If a host needs GraphQL across shards or partitioned tables, keep routing in
the Rails/ActiveAdmin request boundary (middleware, `connected_to`, custom
finder). Do not invent gem DSL until a concrete host failure and RFC name the
contract (shard key in GraphQL args, role switching, cross-shard batch limits).

Optional later: document “unsupported / inherited only” next to identity in
`docs/graphql-api.md` when a reader asks again.

## Source

lib/active_admin/graphql/resource_identity.rb
lib/active_admin/graphql/record_source.rb
lib/active_admin/graphql/resource_query_proxy.rb
spec/dummy/config/database.yml
rfcs/0007-graphql-identity.md
docs/issues/20261010111159_rails-composite-primary-keys-alignment.md
polyrun.yml (test shards only)
