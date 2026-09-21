# RFC 0006: Mutation permit_params

- Feature Name: mutation-permit-params
- Type: Standards Track
- Status: Proposed
- Created: 2026-09-21
- Author: Andrei Makarov
- Stakeholders: project maintainers, GraphQL admin client authors
- Feedback until: 2026-10-05
- Relates: RFC 0004

## Summary

Add `permit_params` on the per-resource `graphql` block, with nested `create` and `update` blocks, so create and update input objects can list different columns than the query object type.

## Motivation

`only` and `except` feed `attributes_for_graphql`, which builds both the resource object type and `graphql_assignable_attribute_names`. Create and update inputs share that list. An application that must show calculated status or timestamps on queries cannot hide those columns from mutation inputs without also hiding them from reads. Default ActiveAdmin `resource_attributes` includes timestamps, so a client can persist `created_at` on create. HTML admin already splits that surface: `index` / `show` / `form` for reads, `permit_params` for writes. GraphQL had no write list.

## Guide-level explanation

Readable fields stay on `only` / `except`. Mutation inputs default to that assignable set minus a single-column primary key and minus `created_at` / `updated_at`. Narrow writes without hiding reads:

```ruby
ActiveAdmin.register Post do
  permit_params :title, :body

  graphql do
    graphql_name "BlogPost"

    create do
      permit_params :title, :body, :starred
      resolve do |proxy:, attributes:, **|
        proxy.build_new(attributes)
      end
    end

    update do
      permit_params :title, :body
    end
  end
end
```

Top-level graphql `permit_params` (alias `permit`) sets both mutation inputs. A static HTML `permit_params :title, :body` seeds GraphQL when the graphql list is unset. A request-time HTML block is not copied. Nested `create` / `update` `permit_params` replace that shared list for one operation. Nested `resolve` is the graphql-ruby pairing used by `member_action_mutation`; `resolve_create` / `resolve_update` remain. Names missing from `only` / `except` never become writable. Empty `permit_params` yields an input with no column arguments; graphql-ruby `has_no_arguments(true)` is set so the type stays valid. `destroy_*` is an alias of `delete_*`. `graphql_name` is an alias of `type_name`.

Introspection of `PostCreateInput` and `PostUpdateInput` is the contract. Unknown input fields fail GraphQL validation. `spec/requests/graphql_mutation_permit_params_spec.rb` covers default timestamp omission, HTML seeding, shared and nested `permit_params`, refusal to widen past `only`, empty inputs, `create { resolve }`, `graphql_name`, and `destroy_post`.

## Reference-level explanation

Start from `graphql_assignable_attribute_names` (RFC 0004 `only` / `except`, minus a single primary key).

Create names: if `create { permit_params }` is set, intersect with that list; else if top-level graphql `permit_params` is set, intersect with that; else if static HTML `permit_params` args were stored, intersect with those; else the base minus `created_at` and `updated_at`. Update names use the update nested list in place of create. `nil` means unset. `[]` means no columns. belongs_to parent ids remain on the input when configured.

`SchemaBuilder` builds `*CreateInput` from create names and `*UpdateInput` from update names. Default resolvers slice the GraphQL input with the same lists before `save` / `update`. Failed `save` / `update` raise `GraphQL::ExecutionError` with `extensions.errors` set to `record.errors.full_messages`. The mutation field still returns the resource object (RFC 0004). `ResourceQueryProxy#build_new` still permits `graphql_assignable_attribute_names` so a create `resolve` hook can set server-owned readable columns. Destroy registers both `delete_*` and `destroy_*` against one resolver.

## Security considerations

Client mutation arguments are an extra-field write surface. The generated input type is the trusted-layer allowlist. The resolver slice is defense in depth. `only` remains the ceiling.

## Registrar

DSL: `permit_params` (`permit`), `create`, `update`, `graphql_name` (alias of `type_name`). Nested: `permit_params`, `resolve`. Mutation fields: `destroy_*` alias of `delete_*`. Resource methods: `graphql_create_attribute_names`, `graphql_update_attribute_names`.

## Drawbacks

`graphql { create do }` is a second `create` word beside the Rails action. A request-time HTML `permit_params` block is not copied into the schema. `delete_*` remains beside `destroy_*`. CRUD mutations still return the resource object rather than a graphql-ruby `Schema::Mutation` payload type.

## Rationale and alternatives

`create_only` / `update_only` collide with `accepts_nested_attributes_for update_only:` and `upsert_all update_only:`. Nested blocks match `form do` and `member_action_mutation do`. Omitting timestamps by default matches ActiveAdmin `generators/boilerplate.rb` `assignable_attributes`. Returning a `{ record, errors }` payload would break RFC 0004 field types; validation failures use ExecutionError extensions instead.

## Prior art

ActiveAdmin `permit_params`. Rails `params.permit`. graphql-ruby `argument` / `resolve` pairing. RFC 0004 `only` / `except`.

## Unresolved questions

Whether `configure` should run on create and update input classes. Whether CRUD mutations should return graphql-ruby payload objects in a later RFC.

## Future possibilities

Required create arguments. Input-object `configure`. graphql-ruby payload return types for create and update.
