# RFC 0008: GraphQL capabilities

- Feature Name: graphql-capabilities
- Type: Standards Track
- Status: Proposed
- Created: 2026-10-12
- Author: Andrei Makarov
- Relates: RFC 0004, RFC 0005

## Summary

Per-resource GraphQL DSL associates many fields, queries, and mutations with one
named capability. The HTTP context carries the granted set. Missing capability
hides the member when schema visibility is on and denies resolve always.
Capabilities do not replace ActiveAdmin authorization.

## Motivation

OAuth scopes and similar grants need one name for several schema members. A host
proc per field drifts. Surface toggles are build-time only. Authorization alone
leaves forbidden fields in introspection.

## Guide-level explanation

Declare once, attach many members:

```ruby
ActiveAdmin.register Post do
  graphql do
    capability :pii do
      fields :title, :body
    end

    capability :editor do
      queries :index, :show
      mutations :create, :update, :destroy
    end

    capability :publish do
      member_actions :publish
    end
  end
end
```

Grant capabilities per request:

```ruby
config.namespace :admin do |admin|
  admin.graphql_capabilities = lambda { |ctx|
    Array(ctx[:current_user]&.oauth_scopes)
  }
end
```

Enable `graphql_visibility` when introspection must omit ungated members.
Resolve still fails closed when the capability is absent.

## Reference-level explanation

- Capability names are symbols. The context key is `:capabilities` (Enumerable
  normalized to a Set of symbols).
- `graphql_capabilities` is an optional namespace proc `(context_hash) -> Enumerable`.
  The controller merges the result into `context[:capabilities]`.
- Resource DSL: `capability(name, **lists, &block)`. Block and kwargs may set
  `fields`, `queries`, `mutations`, `member_actions`, `batch_actions`,
  `collection_actions`.
- Query aliases: `index`/`list` → `:collection`, `show` → `:member`.
- Mutation aliases: `delete` → `:destroy`. CRUD keys are `:create`, `:update`,
  `:destroy`. Aggregate run-action keys are `:batch_action`, `:member_action`,
  `:collection_action`. Prefixed keys (`:member_publish`) and
  `member_actions :publish` are equivalent.
- A schema member may map to at most one capability. Reassignment raises.
- `SchemaField` accepts `capability:`. `#authorized?` requires the capability
  when set (fail closed if `:capabilities` is missing or lacks the name).
  `#visible?` applies the same capability gate only when namespace
  `graphql_visibility` is enabled, so hosts without the visibility plugin keep
  legacy Warden behavior and still deny at authorize time.
- Object `fields:` cover generated attributes and wired `belongs_to` association
  fields. Schema build raises when a declared field name is missing on the type.
- `graphql_capabilities` forces `dynamic: true` visibility and MUST NOT be
  combined with named visibility `profiles:` (cached profile context ignores
  per-request capabilities). The HTTP context omits `visibility_profile` when
  the capabilities proc is set.
- Authorization adapter checks still run when field authorization is enabled.
- Subscriptions and streaming transports are out of scope.

## Security considerations

Capabilities are additive gates. Hosts MUST still configure ActiveAdmin
authorization. Visibility without authorize is insufficient. Fail closed when a
member requires a capability and the context set is absent.

## Registrar

DSL: `capability`, `fields`, `queries`, `mutations`, `member_actions`,
`batch_actions`, `collection_actions`. Namespace: `graphql_capabilities`.
Context: `:capabilities`. Field keyword: `capability:`.

## Drawbacks

Hosts must populate `:capabilities`. Introspection hiding needs
`graphql_visibility`. Two knobs (capability and authorize) can confuse if
undocumented.

## Rationale and alternatives

Capability-first DSL matches “one grant, many members.” Per-field require lists
invert the association and hurt reuse. Separate schemas per scope explode.
Vendor OAuth APIs stay in the host mapping proc.

## Prior art

graphql-ruby `visible?` / `authorized?`, OAuth scope checks, ActiveAdmin
authorization adapters, RFC 0005 visibility note.

## Unresolved questions

Whether policy payloads should list field-level capabilities. Whether mutation
input attributes get a separate capability map.

## Future possibilities

Transport gates for subscriptions. Default visibility profile that mirrors
capabilities. Input-attribute allowlists per capability.
