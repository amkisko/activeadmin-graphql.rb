# Rails composite primary keys alignment

## Participants

Andrei Makarov

## Decisions

Treat ActiveRecord composite primary keys and GraphQL `identity` as related but
not identical contracts. Keep GraphQL `id` as a single `ID!` string. Do not
adopt Rails form URL underscore packing as the default GraphQL id encoding.

Record alignment against the Rails guide Composite Primary Keys
(https://guides.rubyonrails.org/active_record_composite_primary_keys.html)
after shipping inferred id columns and RFC 0007 identity DSL.

## Effects

Compared gem behavior to the guide’s model, query, form, and parameter rules.

ActiveRecord composite primary key (self.primary_key = array):

- Aligns: model declares composite key the same way as the guide’s
  `self.primary_key = [:store_id, :sku]` style. Dummy `LibraryEdition` uses
  `[:book_code, :seq]`.
- Aligns: internal batch and find paths convert that string id into an ordered
  value list and use Rails tuple/`Relation#find` style lookups
  (`ActiveAdmin::PrimaryKey.dataloader_tuple`, `ResourceQueryProxy` composite
  branch). That matches the guide’s `Product.find([3, "XYZ12345"])` and
  `where(primary_key => [[...], [...]])` idea at the Ruby API layer.
- Diverges: GraphQL and the published docs encode composite `id` as a JSON
  object string (`{"book_code":"CPK","seq":7}`), not as the guide’s form/URL
  underscore packing (`/books/2_25` with `params.extract_value(:id)`). JSON
  keeps column names explicit and avoids ambiguity when a key value contains
  `_`. Underscore packing is not accepted as GraphQL `id` today.
- Diverges: GraphQL also accepts per-key arguments and `WhereInput` fields for
  composite models. The guide’s controller example extracts one `:id` param
  into an array; we keep named keys as a GraphQL-friendly alternate.
- Aligns with guide caution: `where(id: ...)` / `find_by(id:)` on composite
  models can mean an `:id` attribute, not the full primary key. The gem’s
  GraphQL `id` field is the ActiveAdminResource identity string, not
  necessarily an ActiveRecord `:id` column. Member lookup uses primary-key
  columns (or configured identity), not a bare `where(id: graphql_id)` on
  composite models.

Keyless views and RFC 0007 `graphql { identity ... }`:

- Outside the guide’s scope. The guide assumes a declared composite primary
  key on the table/model. AlertEvent-style views with `primary_key = nil` and
  a virtual Ruby `id` are not Rails composite primary keys.
- `identity :a, :b, :c, separator: ":"` is an application-level encoding so
  GraphQL can share the same string as a hand-rolled `def id; [...].join(":")`.
  That separator form is closer in spirit to Rails’ delimited URL id than our
  JSON composite encoding, but the delimiter and segment rules are app-chosen,
  not `extract_value`’s underscore default.
- Without `separator`, configured multi-column identity reuses the gem’s JSON
  object string so keyless and AR-composite GraphQL ids stay one family.

Stock ActiveAdmin HTML member routes still need a composite-aware
`find_resource` (or custom finder) for AR composite keys; GraphQL does not
make Rails form URLs use JSON.

## Next

Leave GraphQL composite `id` as JSON for AR composite primary keys unless a
later RFC deliberately adds underscore (or `extract_value`-compatible) accept
and emit. Document that choice next to the Rails guide, not as “the same
format Rails uses for casting composite ids” without qualification.

No change required for RFC 0007 separator identity; it is the escape hatch
when the model is not a Rails composite primary key.

## Source

https://guides.rubyonrails.org/active_record_composite_primary_keys.html
docs/graphql-api.md (Nonconventional primary keys, Composite primary keys)
rfcs/0007-graphql-identity.md
lib/active_admin/primary_key.rb
lib/active_admin/graphql/resource_identity.rb
spec/dummy/app/models/library_edition.rb
spec/dummy/app/models/alert_event.rb
