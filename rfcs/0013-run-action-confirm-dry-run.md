# RFC 0013: Confirm, dry-run, and run_action_field

- Feature Name: run-action-confirm-dry-run
- Type: Standards Track
- Status: Proposed
- Created: 2026-10-12
- Author: Andrei Makarov
- Relates: RFC 0010

## Summary

`SchemaField` accepts `dry_run:`, `confirm:`, and optional `preview:` for custom
run-action fields. `RunActionField.define` registers the field and resolver
without reopening the Mutation class. When `preview` is set, dry-run and refused
preview short-circuit like member actions (RFC 0010).

## Motivation

Custom mutations in `graphql_configure_schema` repeat confirm/dry-run wiring and
often need a preview path that must not call the side-effecting resolve. A small
DSL removes `define_method` boilerplate and aligns preview behavior with
`member_action_mutation dry_run:`.

## Guide-level explanation

```ruby
admin.graphql_configure_schema = lambda do |schema|
  ActiveAdmin::GraphQL::RunActionField.define(
    schema.mutation,
    :create_batch,
    capability: :support_act,
    dry_run: true,
    confirm: true
  ) do
    argument :q, GraphQL::Types::JSON, required: true, camelize: false

    preview do |q:, **|
      q.present? ? ok("would_run:create_batch") : refuse("q_required")
    end

    resolve do |q:, **|
      HostService.call(q: q)
    end
  end
end
```

Behavior:

- `confirm: true` and both `confirm` and `dry_run` false →
  `body: "confirm_required"` without calling `resolve` or `preview`.
- `preview` present and `dry_run: true` → return preview (or
  `would_run:<field_name>` if preview returns nil); do not call `resolve`.
- `preview` present, not dry-run, preview refused → return refusal; do not call
  `resolve`.
- Otherwise call `resolve` (including dry-run when no preview is configured, so
  hosts may still branch on `dry_run:` inside resolve).

Low-level `schema.mutation.field … preview:` remains available for hosts that
prefer explicit `define_method`.

## Reference-level explanation

- Keywords on `SchemaField`: `dry_run:`, `confirm:` (Boolean, default false),
  `preview:` (optional Proc).
- When `dry_run` / `confirm` are enabled, inject Boolean arguments (default
  `false`, `camelize: false`) before the field block runs.
- `RunActionControlExtension` implements confirm gate and preview short-circuit.
  It is attached when `confirm` is true or `preview` is set.
- `preview` runs in `RunActionPreview` (helpers `ok` / `refuse`). Keyword args
  are the field arguments plus `context:`.
- `ActiveAdmin::GraphQL::RunActionField.define(owner, name, **opts, &block)`:
  - opts: `type:` (default `RunActionPayload`), `null:`, `camelize:`,
    `dry_run:`, `confirm:`, `capability:`, `authorize:`, `visibility:`, plus
    other `SchemaField` kwargs;
  - block DSL: `argument`, `arguments`, `preview`, `resolve`, `ok`, `refuse`;
  - requires `resolve`; defines the owner method with that proc;
  - does not use `class_eval`.
- Optional `graphql_run_action_audit` receives short-circuit outcomes with
  `action` equal to the GraphQL field name.
- The gem does not interpret host JSON payload keys.

## Security considerations

Confirm gate is advisory UX unless the host service also requires confirm.
When `preview` is set, dry-run and refused preview MUST NOT call `resolve`.
Without `preview`, dry-run still invokes `resolve` with `dry_run: true`.

## Registrar

Field keywords: `dry_run:`, `confirm:`, `preview:`. Module:
`ActiveAdmin::GraphQL::RunActionField`, `RunActionControlExtension`,
`RunActionPreview`. Result body: `confirm_required`, default dry-run
`would_run:<field_name>`.

## Drawbacks

Two dry-run shapes remain: with preview (short-circuit) and without (resolve
still runs). Hosts must choose explicitly.

## Rationale and alternatives

`RunActionField.define` avoids recommending `class_eval`. Sharing
`RunActionPreview` with RFC 0010 keeps `ok` / `refuse` consistent. A Mutation
subclass factory was rejected as heavier for one-off host fields.

## Prior art

RFC 0010 member dry-run; `RunActionPayload`; graphql-ruby `field` +
`define_method`.

## Unresolved questions

None for this revision.

## Future possibilities

`collection_action_mutation` dry-run using the same control extension.
