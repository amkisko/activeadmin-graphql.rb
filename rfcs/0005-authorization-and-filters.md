# RFC 0005: Authorization and filters

- Feature Name: authorization-and-filters
- Type: Standards Track
- Status: Stable
- Created: 2026-08-18
- Author: Andrei Makarov
- Relates: RFC 0002, RFC 0004

## Summary

GraphQL authorization and filters follow the ActiveAdmin resource. Nested `belongs_to` fields apply read authorization. List queries accept Ransack `q`, menu `scope`, and sort `order`.

## Motivation

A field that stays queryable after the HTML admin hid it, or a `belongs_to` parent that loads without the same read authorization, is a second permission model. Clients then encode a schema this gem can no longer keep honest.

## Guide-level explanation

Use the same authorization adapter as the admin UI. Nested `belongs_to` fields apply read authorization. Filters match the HTML index: Ransack `q`, scopes, and `order`.

Visibility plugins (`graphql_visibility`, `graphql_schema_visible`) are namespace options. They do not replace ActiveAdmin authorization.

## Reference-level explanation

Authorization MUST match the resource adapter used for HTML. HTTP caps are RFC 0003. Schema field names are RFC 0004.

## Drawbacks

Hosts cannot expose a looser GraphQL read model without changing ActiveAdmin authorization. Visibility plugins add a second knob that can be mistaken for authorization.

## Rationale and alternatives

A GraphQL-only policy would drift from the admin UI. Skipping `belongs_to` read checks would leak parent records. Doing nothing leaves the HTML admin as the only honest surface.

## Prior art

ActiveAdmin authorization adapters, Ransack, Pundit/CanCanCan. graphql-ruby visibility. RFC 0002 requires authorization to follow ActiveAdmin.

## Unresolved questions

Whether visibility profiles should become a dedicated RFC when a second profile set ships.
