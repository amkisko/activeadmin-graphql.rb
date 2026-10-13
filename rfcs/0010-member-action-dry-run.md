# RFC 0010: Member action dry-run and preview

- Feature Name: member-action-dry-run
- Type: Standards Track
- Status: Proposed
- Created: 2026-10-12
- Author: Andrei Makarov
- Relates: RFC 0004, RFC 0008

## Summary

`member_action_mutation` accepts `dry_run: true`, injects a Boolean `dry_run`
argument, runs an optional `preview` before the ActiveAdmin action, and
enforces an `extra_params` allowlist. An optional namespace audit hook records
outcomes without owning product audit storage.

## Motivation

Hosts repeat dry-run argument wiring and resolve wrappers on every allowlisted
member action. Preview policy is domain-specific; the control flow is generic.

## Guide-level explanation

```ruby
graphql do
  member_action_mutation :publish, dry_run: true do
    preview do |record, **|
      if record.may_publish?
        ok("would_run:publish:#{record.id}")
      else
        refuse("not_publishable")
      end
    end
    extra_params :from
  end
end
```

Resolver order: load member, run `preview`, if `dry_run` return preview without
`run_member_action`, if preview refused return refusal without running, else
run the member action. Optional audit:

```ruby
admin.graphql_run_action_audit = lambda { |context, meta|
  # meta: action, id, status, dry_run, reason, ok
}
```

## Reference-level explanation

- `member_action_mutation(name, dry_run: false, capability: nil, &block)`.
- When `dry_run: true`, the per-action field gains argument `dry_run`
  (`Boolean`, default `false`, `camelize: false`) with a schema description.
- DSL: `preview { |record, **| … }`, `extra_params(*keys)`, helpers `ok(body)`
  and `refuse(body, status: 422)` returning `RunActionPayload::Result`.
- Preview runs in a context object that defines `ok` / `refuse`. Keyword args
  include at least `proxy`, `context`, `aa_resource`, `auth`, `action`, `id`,
  `params`.
- `extra_params` allowlists GraphQL keyword args forwarded into the AA request.
  `id` is never rebound from extras. Keys outside the allowlist are dropped
  when an allowlist is set; when unset, existing keyword merging behavior
  remains.
- Aggregate `*_member_action(action:)` does not auto-inject dry-run; configure
  the named per-action field.
- `graphql_run_action_audit` is optional. Invoked after a dry-run return, a
  refused preview, or a completed run. Failures in the hook MUST NOT change the
  GraphQL result (log or swallow at host discretion; gem rescues and ignores).
- Same pattern MAY later apply to `collection_action_mutation`.

## Security considerations

Dry-run MUST NOT invoke the controller action. Refused preview MUST NOT invoke
it. Extra params MUST NOT override member `id`.

## Registrar

DSL: `dry_run:`, `preview`, `extra_params`, `ok`, `refuse`. Namespace:
`graphql_run_action_audit`.

## Drawbacks

Preview bodies stay host-defined strings; the gem does not standardize reason
codes.

## Rationale and alternatives

Built-in argument and order beats per-app prepends. Full dry-run simulation of
controller side effects is out of scope.

## Prior art

ActiveAdmin member actions; `RunActionPayload`; RFC 0004 run-action mutations.

## Unresolved questions

Whether batch actions need the same dry-run flag in this RFC or a follow-on.

## Future possibilities

`collection_action_mutation … dry_run: true`. Shared preview result type beyond
`RunActionPayload::Result`.
