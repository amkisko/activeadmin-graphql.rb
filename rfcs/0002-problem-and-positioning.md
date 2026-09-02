# RFC 0002: Problem and positioning

- Feature Name: problem-and-positioning
- Type: Informational
- Status: Stable
- Created: 2026-08-17
- Updated: 2026-08-18
- Author: Andrei Makarov
- Relates: RFC 0003, RFC 0004, RFC 0005

## Summary

activeadmin-graphql exposes ActiveAdmin resources over GraphQL HTTP, with authorization and filters aligned to the admin. The endpoint is off until a namespace sets `graphql = true`.

## Motivation

Admin apps already declare resources, authorization, scopes, Ransack filters, and member actions. A second hand-written GraphQL schema drifts: a field remains queryable after the HTML admin hid it, or a `belongs_to` parent loads without the same read authorization. Clients then encode a schema that only this gem can keep honest.

The HTTP surface is a contract with those clients. Default is `POST /admin/graphql`. Invalid JSON is HTTP 400. Namespace options cap multiplex size, query complexity, query depth, and batch-action id lists. Changing field names, enum type names, mutation input shapes, or those caps without a numbered RFC breaks existing clients.

Authorization must follow ActiveAdmin. Nested `belongs_to` fields apply read authorization. Optional `graphql do ... end` on a resource customizes the schema without a parallel registry.

## Guide-level explanation

Set `admin.graphql = true` in ActiveAdmin setup. POST to `/admin/graphql` by default. Optional `admin.graphql_path` changes the segment. Optional `graphql do ... end` on a resource customizes fields.

## Drawbacks

Generated schema names couple clients to ActiveAdmin. Opt-in means the route is absent until configured.

## Rationale and alternatives

Generating the schema from ActiveAdmin registration keeps one source of resource truth. A standalone graphql-ruby schema beside ActiveAdmin would let API and admin diverge on day two. JSON and XML admin endpoints already exist. GraphQL is an opt-in namespace feature: routes stay off until `graphql = true`.

## Prior art

ActiveAdmin, graphql-ruby, Ransack. Contract detail is RFC 0003 through RFC 0005.

## Unresolved questions

Whether the GraphQL schema layout should split from the HTTP endpoint (RFC 0004).

Whether multiplex, complexity, and batch-id caps should freeze as a dedicated registrar (RFC 0003).
