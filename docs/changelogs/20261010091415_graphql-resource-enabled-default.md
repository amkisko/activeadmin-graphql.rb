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

Consumers that expose a narrow GraphQL surface should set
`graphql_resource_enabled_default = false` in the ActiveAdmin namespace and add
`graphql` blocks only where the API should include the resource.

## Source

CHANGELOG Unreleased. docs/graphql-api.md namespace settings and per-resource
DSL. spec/requests/graphql_resource_enabled_default_spec.rb.
