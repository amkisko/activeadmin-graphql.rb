# Nonconventional id fields

## Effects

Schema build no longer raises `GraphQL::Schema::DuplicateNamesError` when a
registered model has an `id` column that is not the ActiveRecord primary key
(`self.primary_key = nil`) or uses a non-`id` primary key.

`ActiveAdmin::PrimaryKey` falls back to an `id` column when the declared
primary key is blank. Object types skip emitting a column field named `id`
(interface owns GraphQL `id`) and expose a single non-`id` primary-key column
as a readable scalar unless the resource's attribute configuration omits it.
Models with neither a primary key nor an `id` column fail schema build with an
`ArgumentError` that asks for `self.primary_key`. On 0.3.0 those models could
still enter the schema with a broken GraphQL `id`. Apps that keep such a
resource registered must set `self.primary_key` or use `graphql { disable! }`
so the rest of the namespace schema still builds. Inferred `id` values must be
unique and non-null; ambiguous member and batched lookups fail closed.

Member lookup uses the inferred column while preserving an explicitly
configured ActiveAdmin finder. Request-local policy caching keeps separate
entries for distinct records when ActiveRecord has no declared primary key.

Dummy coverage includes SQLite views that project `code AS id` and
`id AS row_key`, plus a table with an `id` column and no primary key.

## Later pass 2026-10-10

Downstream check: a database view with neither primary key nor `id` column
could stay GraphQL-disabled via `graphql { disable! }`. Spec covers that
escape hatch next to the ArgumentError path.

Later the same day: RFC 0007 adds `graphql { identity ... }` so those views
can stay enabled when columns (and optional separator) are declared. See
docs/changelogs/20261010110600_graphql-identity-dsl.md.

## Next

Core fix shipped in 0.3.1. Identity DSL follow-on is 0.3.2.

## Source

- Specs: `spec/requests/graphql_identity_columns_spec.rb`,
  `spec/unit/primary_key_identity_spec.rb`,
  `spec/unit/resource_query_proxy_identity_spec.rb`,
  `spec/unit/policy_set_cache_spec.rb`
- Views: `spec/dummy/db/schema.rb` (`string_id_records`, `alternate_key_records`)
- Follow-on: docs/changelogs/20261010110600_graphql-identity-dsl.md
