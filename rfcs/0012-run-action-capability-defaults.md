# RFC 0012: Default run-action capabilities

- Feature Name: run-action-capability-defaults
- Type: Standards Track
- Status: Proposed
- Created: 2026-10-12
- Author: Andrei Makarov
- Relates: RFC 0008, RFC 0010

## Summary

Namespace settings supply a default capability for batch, member, and collection
run-action mutation fields when the resource has not assigned one. Per-kind DSL
`capability:` on `batch_action_mutation`, `member_action_mutation`, and
`collection_action_mutation` sets an explicit override.

## Motivation

Hosts otherwise walk allowlists after ActiveAdmin load to stamp the same
capability on every run action, racing schema cache clears and duplicating the
allowlist. Member actions were the first case; batch and collection need the
same default.

## Guide-level explanation

```ruby
admin.graphql_member_action_capability_default = :support_act
admin.graphql_batch_action_capability_default = :support_act
admin.graphql_collection_action_capability_default = :support_act

ActiveAdmin.register Post do
  graphql do
    capability :support_act do
      member_actions :publish
      batch_actions :star_these
      collection_actions :export
    end
    # or per field / aggregate:
    member_action_mutation :archive, capability: :support_act
    batch_action_mutation capability: :support_act
    collection_action_mutation :export, capability: :support_act
  end
end
```

## Reference-level explanation

- Defaults are `nil` (no implicit capability; current RFC 0008 behavior).
- Resolution order for a per-action field (`posts_member_<action>`,
  `posts_collection_<action>`) or a named batch action at resolve time:
  1. DSL `capability:` on that action’s (or aggregate) run-action config;
  2. `capability_for_mutation(:<kind>_<action>)` from the resource capability
     map;
  3. `graphql_<kind>_action_capability_default` (`kind` is `member`, `batch`,
     or `collection`).
- Aggregate fields (`*_member_action`, `*_batch_action`,
  `*_collection_action`) use the same order with map keys `:member_action`,
  `:batch_action`, and `:collection_action`.
- Batch actions expose one aggregate GraphQL field; the namespace batch default
  gates that field and each `batch_<action>` authorize check.
- Custom mutations registered via `graphql_configure_schema` already accept
  `capability:` on `SchemaField`; unchanged.
- Setting a default does not invent run-action fields; it only gates fields the
  schema already builds.

## Security considerations

A non-nil default fails closed for every matching run-action field without an
explicit map entry. Hosts MUST grant the capability in `graphql_capabilities`
for callers that should see those mutations.

## Registrar

Namespace: `graphql_member_action_capability_default`,
`graphql_batch_action_capability_default`,
`graphql_collection_action_capability_default`. DSL keyword: `capability:` on
`batch_action_mutation`, `member_action_mutation`, and
`collection_action_mutation`. Module: `ActiveAdmin::GraphQL::RunActionCapability`.

## Drawbacks

A broad default can hide actions the host meant to leave ungated. Opt-in nil
defaults preserve compatibility.

## Rationale and alternatives

Resource `capability { member_actions / batch_actions / collection_actions … }`
remains the precise form. Namespace defaults remove after-load sync loops when
every action of a kind shares one grant.

## Prior art

RFC 0008 capability maps; surface-toggle namespace defaults.

## Unresolved questions

None for this revision.

## Future possibilities

Shared helper that applies one default to all three kinds in one assignment.
