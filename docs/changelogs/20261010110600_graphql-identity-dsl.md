# GraphQL identity DSL (RFC 0007)

## Decisions

Ship `graphql { identity *columns, separator:, encode:, decode: }` so resources
without an ActiveRecord primary key and without an `id` column can stay in the
schema. Prefer resource configuration over forcing `self.primary_key`.

Separator form matches HTML admins that use a virtual `id` method such as
`[entry_type, entry_id, event_type].join(":")`. Without separator, multi-column
identity keeps the existing composite JSON string.

## Effects

Schema build, member lookup, mutations that resolve by where/id, and policy
cache keys go through `ActiveAdmin::GraphQL::ResourceIdentity` when identity is
configured. Ambiguous matches still fail closed.

Dummy coverage: view `alert_events` / model `AlertEvent` with virtual composite
`id`.

## Next

Folded into 0.3.1 release metadata. Tag and gem push wait on make release.

## Source

rfcs/0007-graphql-identity.md
docs/changelogs/20261010101500_nonconventional-id-fields.md
docs/issues/20261010111159_rails-composite-primary-keys-alignment.md
https://guides.rubyonrails.org/active_record_composite_primary_keys.html
spec/unit/resource_identity_spec.rb
spec/requests/graphql_identity_dsl_spec.rb
