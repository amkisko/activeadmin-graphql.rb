# Host customization gaps

## Decisions

The gem owns mechanics: when a field is visible, null, or omitted; dry-run
argument wiring; filter-key policy hooks; default member-action capability;
confirm/dry_run injection on custom fields. Hosts own product grants, domain
preview bodies, and audit storage.

Capabilities remain grant names in context[:capabilities]. Named visibility
profiles stay incompatible with graphql_capabilities.

## Effects

RFCs 0009–0013 specify the contract. Implementation landed on the feature
branch with request coverage for each hook.

## Next

Publish a release. Hosts migrate off local prepends in the order: capability
null mode and dry-run DSL, then collection policy, then field_visible and
capability defaults, then confirm helpers.

## Source

RFCs 0009–0013. docs/changelogs/20261012200000_host-customization-hooks.md.
