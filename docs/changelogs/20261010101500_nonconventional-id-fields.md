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
`ArgumentError` that asks for `self.primary_key`. Inferred `id` values must be
unique and non-null; ambiguous member and batched lookups fail closed.

Member lookup uses the inferred column while preserving an explicitly
configured ActiveAdmin finder. Request-local policy caching keeps separate
entries for distinct records when ActiveRecord has no declared primary key.

Dummy coverage includes SQLite views that project `code AS id` and
`id AS row_key`, plus a table with an `id` column and no primary key.

## Next

Ship in the next gem release after 0.3.0.

## Source

- Specs: `spec/requests/graphql_identity_columns_spec.rb`,
  `spec/unit/primary_key_identity_spec.rb`,
  `spec/unit/resource_query_proxy_identity_spec.rb`,
  `spec/unit/policy_set_cache_spec.rb`
- Views: `spec/dummy/db/schema.rb` (`string_id_records`, `alternate_key_records`)
