# RFC 0009: Field capability mode and field visibility hook

- Feature Name: field-capability-mode
- Type: Standards Track
- Status: Proposed
- Created: 2026-10-12
- Author: Andrei Makarov
- Relates: RFC 0008

## Summary

Per-field `capability_mode` chooses whether a missing capability omits the
field from the schema (`:omit`, default) or keeps it visible and resolves to
`null` (`:null`). An optional namespace hook `graphql_field_visible` can omit
fields independently of capabilities.

## Motivation

RFC 0008 omit-on-miss matches allowlists that shrink introspection. Some
columns must remain selectable and return `null` when the grant is absent so
clients keep a stable selection set. Hosts also need a second omit gate for
dynamic allowlists without replacing capability grants.

## Guide-level explanation

```ruby
ActiveAdmin.register User do
  graphql do
    capability :pii_contact, fields: %i[email phone_number], mode: :null
    capability :support_read, fields: %i[blocked], mode: :omit
  end
end
```

Or on a custom field: `capability: :pii_contact, capability_mode: :null`.

Namespace defaults and the optional visibility hook:

```ruby
admin.graphql_field_capability_mode_default = :omit
admin.graphql_field_visible = lambda { |context, meta|
  # meta: graphql_type_name, field_name, resource (and visibility hash keys when present)
  true
}
```

## Reference-level explanation

- Modes are symbols `:omit` and `:null`. Unknown modes raise at schema build or
  DSL assign time.
- Default mode is namespace `graphql_field_capability_mode_default` (`:omit`).
  DSL `capability … mode:` and field keyword `capability_mode:` override per
  field. Mode without a capability is ignored.
- With `graphql_visibility` enabled and mode `:omit`, missing capability makes
  `SchemaField#visible?` false (RFC 0008).
- With mode `:null`, missing capability does not hide the field. `#authorized?`
  still requires the capability so nullable fields resolve to `null`.
- Wired `belongs_to` fields honor the same capability and mode maps as
  attributes.
- `graphql_field_visible` is optional `Proc` `(context, meta) -> Boolean`.
  Default `nil` means all fields pass. Returning false omits the field after
  `super` and before or with the existing `graphql_schema_visible` stack.
  Capability mode still applies after this hook returns true.
- Named visibility `profiles:` remain incompatible with `graphql_capabilities`
  (RFC 0008).

## Security considerations

`:null` keeps the field name in introspection. Hosts MUST still authorize
records. Fail closed when the capability set is missing for a gated field.

## Registrar

Field keyword: `capability_mode:`. Capability DSL: `mode:` on `capability` /
`fields`. Namespace: `graphql_field_capability_mode_default`,
`graphql_field_visible`.

## Drawbacks

Two omit paths (capability mode and `graphql_field_visible`) need clear docs.
Hosts may confuse OAuth scope strings with capability symbols.

## Rationale and alternatives

Per-field mode avoids a second schema. Global visibility off cannot mix omit
and null. Separate field classes per mode duplicate wiring.

## Prior art

RFC 0008 capabilities; graphql-ruby `visible?` / `authorized?`.

## Unresolved questions

Whether query and mutation root fields need `capability_mode` (out of scope;
object fields and associations only).

## Future possibilities

Input-attribute capability modes. Policy payloads listing field modes.
