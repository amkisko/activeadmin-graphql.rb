# Changelog

## Unreleased

- Add field `capability_mode` (`:omit` / `:null`) and namespace hooks
  `graphql_field_capability_mode_default` and `graphql_field_visible` (RFC 0009).
- Add `member_action_mutation … dry_run: true` with `preview`, `extra_params`,
  `ok` / `refuse`, and optional `graphql_run_action_audit` (RFC 0010).
- Add `graphql_collection_query_policy` and
  `CollectionQueryPolicy.require_visible_fields!`, inferring filter grants from
  resource field capabilities by default (RFC 0011).
- Add `graphql_member_action_capability_default`,
  `graphql_batch_action_capability_default`,
  `graphql_collection_action_capability_default`, and `capability:` on
  `batch_action_mutation` / `member_action_mutation` /
  `collection_action_mutation` (RFC 0012).
- Add `dry_run:` / `confirm:` / `preview:` on `SchemaField`, preview
  short-circuit via `RunActionControlExtension`, and
  `RunActionField.define` DSL sugar for custom run-action fields (RFC 0013).

## 0.3.3 (2026-10-12)

- Add `graphql { capability ... }` and namespace `graphql_capabilities` so one named grant can gate many fields, queries, and mutations (RFC 0008).
- Apply `fields:` capabilities to wired `belongs_to` associations; reject unknown capability field names and named visibility `profiles:` combined with `graphql_capabilities`.
- Add namespace setting `graphql_resource_enabled_default` (`true` by default) and `graphql { enable! }` so apps can opt resources into the schema instead of opting out with `disable!`.
- Add namespace toggles for `registered_resource` and `belongs_to` wiring (`graphql_registered_resource_enabled`, `graphql_belongs_to_associations_enabled`; both `true` by default).
- Add `graphql_policies_enabled` / `graphql_policies_enabled_default` for policy field publishing and per-resource seeds, plus `graphql_policy_adapter` (default `ActiveAdmin::GraphQL::PolicyAdapter`) for payload construction.
- Add per-resource surface defaults and DSL (`graphql_queries_enabled_default`, `graphql_mutations_enabled_default`, `graphql_run_actions_enabled_default`, plus `enable_*!` / `disable_*!`) so apps can trim list/show, CRUD, run-action, and policy fields without disabling the whole resource.
- Treat `queries_enabled` as the read surface: omit `registered_resource` union membership when queries are off; fail schema build when `Query` would have no fields.

## 0.3.2 (2026-10-10)

- Add `graphql { identity ... }` so keyless views can declare GraphQL id columns, optional `separator`, and `encode` / `decode` (RFC 0007).
- Fail schema build when a registered model has neither a primary key nor an `id` column and no `identity` declaration; set `self.primary_key`, use `identity`, or `graphql { disable! }`.

## 0.3.1 (2026-10-10)

- Fix GraphQL identity handling for database views and nonconventional primary keys: keep one `id` field, support inferred `id` lookups, reject ambiguous identifiers, and honor attribute filters.

## 0.3.0 (2026-09-21)

- BREAKING: omit `created_at` and `updated_at` from default create and update inputs. List them on `permit_params` to keep them writable.
- BREAKING: require graphql-ruby 2.6.9 or newer (parser cache Marshal fix).
- Add `permit_params` on the per-resource `graphql` block, with nested `create` / `update` `permit_params` and `resolve` (RFC 0006).
- Seed GraphQL mutation inputs from a static HTML `permit_params` list when graphql `permit_params` is unset.
- Add `destroy_*` as an alias of `delete_*`.
- Add `graphql_name` as an alias of `type_name`.
- Put ActiveRecord validation messages on GraphQL error `extensions.errors` when create or update fails.
- Log GraphQL execute with namespace, operation name, and error count.
- Test ActiveAdmin 4.0.0.beta23 on Rails 8. Keep ActiveAdmin 3.5 on Rails 7.2.
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
