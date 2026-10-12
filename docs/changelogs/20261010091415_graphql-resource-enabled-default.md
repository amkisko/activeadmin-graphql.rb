# GraphQL resource enabled default

## Participants

Andrei Makarov

## Decisions

Add namespace setting `graphql_resource_enabled_default`, default `true`, so
0.3.x behavior stays: turning on the namespace endpoint still includes every
ActiveRecord resource unless `graphql { disable! }` is set.

Apps that want support-style opt-in set the setting to `false`. Then a resource
enters the schema only when registration runs `graphql { }` or
`graphql { enable! }`. `disable!` still omits.

`ResourceConfig` takes the initial `enabled` flag from the namespace setting.
Entering a `graphql` block sets `enabled = true` before the block body runs so
an empty block is a conscious opt-in.

## Effects

New request specs cover default true, default false without a block, empty
block, `enable!`, and `disable!`.

## Next

Folded into 0.3.3 release metadata.

## Source

CHANGELOG 0.3.3. docs/graphql-api.md namespace settings and per-resource
DSL. spec/requests/graphql_resource_enabled_default_spec.rb.
docs/changelogs/20261012113500_release-0-3-3.md.
