# RFC 0007: GraphQL resource identity DSL

- Feature Name: graphql-identity
- Type: Standards Track
- Status: Proposed
- Created: 2026-10-10
- Author: Andrei Makarov
- Relates: RFC 0004
- Feedback until: 2026-10-24

## Summary

Add an optional per-resource `graphql { identity ... }` declaration so GraphQL
`id` and member lookup work for ActiveAdmin models that have no ActiveRecord
primary key and no `id` column, including views that expose a virtual composite
identity in Ruby.

## Motivation

Some admin resources are database views or keyless tables. ActiveAdmin HTML can
still show and find rows when the application defines a virtual `id` method and
a finder. The GraphQL schema builder currently requires either an ActiveRecord
primary key or an `id` column. Without those, schema build raises, so apps must
`graphql { disable! }` even though the HTML admin already works.

## Guide-level explanation

```ruby
ActiveAdmin.register AlertEvent do
  graphql do
    identity :entry_type, :entry_id, :event_type, separator: ":"
  end
end
```

GraphQL `id` becomes `entry_type:entry_id:event_type`. Member queries pass that
same string. Identity columns remain readable fields unless `only` or `exclude`
omits them.

When join and split are not enough:

```ruby
graphql do
  identity :entry_type, :entry_id, :event_type,
    encode: ->(record) { record.id },
    decode: ->(id) {
      entry_type, entry_id, event_type = id.split(":", 3)
      {"entry_type" => entry_type, "entry_id" => entry_id, "event_type" => event_type}
    }
end
```

Resources that already use ActiveRecord primary keys or an inferred `id` column
need no `identity` block.

## Reference-level explanation

### Resolution order for identity columns

For a registered resource `aa_res` and model `M`:

1. If `aa_res.graphql_config` has `identity_columns`, use those strings.
2. Else use `ActiveAdmin::PrimaryKey.columns(M)` (declared primary key, else
   fallback to an `id` column when present).
3. If the resolved list is empty, schema build raises `ArgumentError` naming
   `self.primary_key` and `graphql { identity ... }`.

### Encode

Given columns `C` and optional `separator`, `encode` proc:

- If `encode` is set, call it with the record; coerce the result with `to_s`.
- Else if `C.size == 1`, use `record.public_send(C.first).to_s`.
- Else if `separator` is present, join `C.map { record.public_send(_1) }` with
  that separator.
- Else produce the existing composite JSON object string (column order in `C`).

### Decode

Given a GraphQL id string and optional `decode` proc:

- If `decode` is set, call it; the return value MUST be a Hash of string keys
  usable in `Relation#where` for the identity columns.
- Else if `C.size == 1`, `{C.first => id}`.
- Else if `separator` is present, split with a limit of `C.size` and zip to `C`.
- Else parse as the existing composite JSON object.

Invalid decode input yields no row (member field `null`) or a GraphQL execution
error only when the match is ambiguous (more than one row).

### Member and batch lookup

- When ActiveAdmin `method_for_find` is not `:find`, GraphQL continues to call
  `find_resource` with `params[:id]` equal to the GraphQL id string.
- Otherwise look up with decoded attributes, `limit(2)`, fail closed if two or
  more rows match.
- Batched loads use the same decode attributes in SQL when possible; otherwise
  index the scoped relation by encoded id in Ruby.

### Interface

`ActiveAdminResource.id` remains `ID!`. An ActiveRecord `id` column is never
emitted as a second GraphQL field. Configured identity columns other than `id`
are readable unless filtered by `only` / `exclude`.

## Registrar

DSL method: `identity` inside `graphql do ... end`.
Config: `identity_columns`, `identity_separator`, `identity_encode_proc`,
`identity_decode_proc`.

## Drawbacks

Apps must declare identity for keyless models; the gem does not infer a Ruby
`id` method. Separators that appear inside column values can break default
split decode; those apps must supply `decode`.

## Rationale and alternatives

Forcing `self.primary_key` couples GraphQL to ActiveRecord find semantics and
can break HTML admin for views. Auto-inferring from `def id` is too implicit.
List-only types without `ID!` would break `ActiveAdminResource`. A resource DSL
keeps HTML and GraphQL aligned when `encode` matches the model `id` method.

## Prior art

ActiveAdmin `defaults finder:`. Rails composite primary keys
(https://guides.rubyonrails.org/active_record_composite_primary_keys.html):
declared `self.primary_key = [...]`, `find` with arrays, form URLs packed with
underscores and `params.extract_value(:id)`. This RFC covers models that are
not Rails composite primary keys (no AR PK / no `id` column). The gem’s AR
composite GraphQL `id` remains a JSON object string, not underscore packing;
see the alignment issue under `docs/issues/` dated 2026-10-10. Existing gem
composite JSON `id` for multi-column ActiveRecord primary keys (RFC 0004).

## Unresolved questions

Whether a later RFC should allow identity without listing columns when only
`encode` / `decode` procs are supplied.

## Future possibilities

Infer identity from a documented ActiveAdmin finder signature. Shared helpers
for common separators.
