# Host customization hooks

## Decisions

Ship generic namespace hooks and DSL for field capability null mode, member-action
dry-run with preview, collection query policy, default run-action capabilities,
and confirm/dry-run/preview plus RunActionField.define for custom mutations.
Product allowlists and auth grants stay in the host application.

## Effects

RFCs 0009 through 0013 claimed and drafted. Implementation under Unreleased in
CHANGELOG.md. Request specs cover null-mode introspection, dry-run short-circuit,
collection filter refusal, default capability omit, and confirm_required.

## Next

Release as 0.4.0 (or next minor) when ready. Host apps can drop prepends that
duplicated these mechanics after upgrading.

## Source

RFCs 0009–0013. Specs under spec/requests/graphql_capability_mode_spec.rb,
graphql_member_action_dry_run_spec.rb, graphql_collection_query_policy_spec.rb,
graphql_run_action_capability_default_spec.rb,
graphql_run_action_confirm_spec.rb.
