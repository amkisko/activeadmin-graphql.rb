# RFC 0011: Collection query policy hook

- Feature Name: collection-query-policy
- Type: Standards Track
- Status: Proposed
- Created: 2026-10-12
- Author: Andrei Makarov
- Relates: RFC 0005, RFC 0008, RFC 0009

## Summary

Namespace hook `graphql_collection_query_policy` runs at the start of
collection resolve. A built-in helper validates Ransack `q` / `order` keys
against schema-visible fields and field capability grants, inferred from the
resource capability map by default.

## Motivation

Restricting filters to visible fields is generic. Product maps for allowlisted
non-predicate keys stay in the host. Requiring a second `field_grants` hash that
duplicates `capability { fields: … }` is avoidable for null-mode columns that
stay visible without the grant.

## Guide-level explanation

```ruby
admin.graphql_collection_query_policy = lambda { |context, meta|
  ActiveAdmin::GraphQL::CollectionQueryPolicy.require_visible_fields!(
    context: context,
    aa_resource: meta[:aa_resource],
    q: meta[:q],
    order: meta[:order],
    allow_q_keys: %w[custom_scope]
  )
}
```

With `capability :pii_contact, fields: %i[email], mode: :null` on the resource,
filtering on `email_cont` requires `pii_contact` in `context[:capabilities]`
even though the field remains schema-visible. Explicit `field_grants` still
overrides or extends the inferred map when needed.

Raise `GraphQL::ExecutionError` to refuse. Return normally to continue.

## Reference-level explanation

- Hook signature: `(context, meta) -> void`. Meta includes `:aa_resource`,
  `:q`, `:scope`, `:order`, `:filter`, and other collection kwargs passed into
  `graphql_resolve_index`. Default `nil` skips the hook.
- Invoked once at the beginning of `graphql_resolve_index`, before custom
  `resolve_index` procs and the default proxy relation.
- `CollectionQueryPolicy.require_visible_fields!` parses `q` Hash keys:
  - keys matching a Ransack `field_predicate` suffix require the field to be
    schema-visible for this context (same visibility stack as object fields,
    including capabilities and `graphql_field_visible` when configured);
  - grant map = resource `field_capabilities` (string keys) merged with optional
    `field_grants` (explicit entries win). Set `infer_field_grants: false` to
    use only `field_grants`;
  - when the grant map lists that field, require the named capability in
    `context[:capabilities]`;
  - keys in `allow_q_keys` pass without field visibility;
  - other keys raise `GraphQL::ExecutionError`.
- `order` strings are checked for the sort column prefix when present.
- The helper does not hard-code product scope names.

## Security considerations

Hosts that skip the hook keep prior behavior. Visibility without authorize is
still insufficient for record access (RFC 0005). Inferring grants from
`:null`-mode field capabilities closes filter bypass when introspection still
shows the column.

## Registrar

Namespace: `graphql_collection_query_policy`. Module:
`ActiveAdmin::GraphQL::CollectionQueryPolicy`. Keywords: `field_grants`,
`infer_field_grants`, `allow_q_keys`.

## Drawbacks

Predicate parsing depends on Ransack’s registered predicates. Exotic custom
predicates need `allow_q_keys` or a host-owned check. Inferring all field
capabilities may refuse filters the host intended to allow without a grant;
use `infer_field_grants: false` or omit the field capability for those columns.

## Rationale and alternatives

A hook plus helper beats baking product allowlists into the gem. Rejecting
inside `resolve_index` only would miss default proxy paths unless both call
sites invoke the same gate; the shared resolver entrypoint covers both.
Duplicating grants in `field_grants` was the interim shape; inference is the
default so null-mode fields stay consistent with RFC 0009.

## Prior art

RFC 0005 filters; Ransack predicates; RFC 0008 / 0009 field capabilities.

## Unresolved questions

Whether typed `filter` input fields need a parallel grant check beyond `q`.

## Future possibilities

Apply the same inference when validating typed `filter` input objects.
