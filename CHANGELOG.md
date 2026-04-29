# Changelog

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
