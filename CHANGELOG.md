# Changelog

## Unreleased

- Add `permit_params` on the per-resource `graphql` block, with nested `create` / `update` `permit_params` and `resolve`, so create and update inputs can omit columns that stay readable on queries (RFC 0006).
- Omit `created_at` and `updated_at` from default create and update inputs; seed those inputs from a static HTML `permit_params` list when graphql `permit_params` is unset.
- Add `destroy_*` as an alias of `delete_*`, and `graphql_name` as an alias of `type_name`.
- Add `rfcs/` starter pack: process (RFC 0001), positioning (RFC 0002), and Standards Track design RFCs 0003–0005 for HTTP endpoint, schema DSL, and authorization.

## 0.2.1 (2026-07-14)

- Add RBS type signatures to the published gem for Steep and other Ruby type checkers
- Add Ruby 4.0 to the supported compatibility matrix
- Return HTTP 400 with a clear error when the GraphQL request body or variables contain invalid JSON
- Return `null` for member queries when the record id does not exist
- Enforce read authorization on `belongs_to` association fields so denied parent records resolve as `null`
- Build GraphQL schemas safely when `schema_for` runs concurrently

## 0.2.0 (2026-04-29)

- Add `activeadmin_policies` GraphQL policy surfaces:
  - global `activeadmin_policies` for resources/pages
  - per-object `activeadmin_policies` on resource objects
  - preflight `activeadmin_policies_for(type_name:, ids:, path:)` for per-record checks before running queries/mutations/actions
- Switch policy payloads to allow-lists (`allowed_actions`, `allowed_member_actions`, `allowed_collection_actions`, `allowed_batch_actions`) and add namespace customization hooks (`graphql_policy_actions`, `graphql_policy_action_mapper`, `graphql_policy_extra`, `graphql_policy_transform`)
- Enforce authorization-by-default for custom GraphQL fields/mutations with explicit opt-out (`authorize: false` / mutation DSL `authorize false`)
- Add namespace defaults/settings and request specs covering policies, customization hooks, and auth-toggle behavior

## 0.1.2 (2026-03-30)

- Fix TruffleRuby compatibility issue with JSON.dump

## 0.1.1 (2026-03-30)

- Fix repository URL in gemspec

## 0.1.0 (2026-03-30)

- Initial release: GraphQL API for ActiveAdmin extracted from the `activeadmin` fork, usable as `gem "activeadmin-graphql"` alongside `activeadmin` and `graphql`.
- Docs: full guide in [`docs/graphql-api.md`](docs/graphql-api.md), including a “Migrating GraphQL clients” section (enum names, typed CRUD inputs, `ActiveAdminKeyValuePair` lists). Links from an optional ActiveAdmin fork or doc site are mainly for discovery.
