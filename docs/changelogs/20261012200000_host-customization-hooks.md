# Host customization hooks

## Decisions

Ship generic namespace hooks and DSL for field capability null mode, member-action
dry-run with preview, collection query policy, default run-action capabilities,
and confirm/dry-run/preview plus RunActionField.define for custom mutations.
Product allowlists and auth grants stay in the host application.

## Effects

RFCs 0009 through 0013 claimed and drafted. Implementation under 0.4.0 in
CHANGELOG.md. Request specs cover null-mode introspection, dry-run short-circuit,
collection filter refusal, default capability omit, and confirm_required.

## Next

Metadata prepared in docs/changelogs/20261013080000_release-0-4-0.md. Run make
release when ready to push the gem and tag. Host apps can drop prepends that
duplicated these mechanics after upgrading.

## Source

RFCs 0009–0013. Specs under spec/requests/graphql_capability_mode_spec.rb,
graphql_member_action_dry_run_spec.rb, graphql_collection_query_policy_spec.rb,
graphql_run_action_capability_default_spec.rb,
graphql_run_action_confirm_spec.rb.
