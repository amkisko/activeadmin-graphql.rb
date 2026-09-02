# RFC 0003: GraphQL HTTP endpoint

- Feature Name: http-endpoint
- Type: Standards Track
- Status: Stable
- Created: 2026-08-18
- Author: Andrei Makarov
- Relates: RFC 0002, RFC 0004

## Summary

GraphQL HTTP is off until a namespace sets `graphql = true`. Default is `POST /admin/graphql`. Invalid JSON is HTTP 400. Namespace options cap multiplex size, complexity, depth, and batch-action ids.

## Motivation

Clients encode a URL and payload shape. Changing the path, returning 500 on invalid JSON, or raising caps without a numbered RFC breaks those clients.

## Guide-level explanation

In ActiveAdmin setup:

```ruby
config.namespace :admin do |admin|
  admin.graphql = true
end
```

Optional `admin.graphql_path` changes the segment under the namespace mount. Defaults: `graphql_path` `"graphql"`, `graphql_multiplex_max` 20, `graphql_max_complexity` 300, `graphql_max_depth` 18, `graphql_batch_action_max_ids` 5000.

## Reference-level explanation

Connection page defaults: `graphql_default_page_size` 25, `graphql_default_max_page_size` 100. Complexity and depth may be set to `nil` to disable. Batch-id cap `0` disables that cap. Invalid JSON MUST be HTTP 400, not 500. Schema construction is RFC 0004.

## Registrar

Namespace settings: `graphql`, `graphql_path`, `graphql_multiplex_max`, `graphql_max_complexity`, `graphql_max_depth`, `graphql_batch_action_max_ids`.

## Drawbacks

Caps are numeric defaults hosts must learn. Opt-in means the route is absent until configured, which surprises clients that assumed it always exists.

## Rationale and alternatives

Always-on GraphQL would expose admin data before authorization review. Returning 500 on bad JSON would look like an application crash. Doing nothing leaves each host to mount graphql-ruby by hand.

## Prior art

graphql-ruby HTTP endpoints. ActiveAdmin JSON and XML admin endpoints. RFC 0002 keeps GraphQL as an opt-in namespace feature.

## Unresolved questions

Whether multiplex, complexity, and batch-id caps should freeze as a dedicated registrar separate from the path.
