# Mutation attribute allowlists

## Participants

Andrei Makarov

## Decisions

RFC 0006 Proposed adds assignable, create_only, update_only, and except_assignable (alias unassignable) on the per-resource graphql block.

only and except stay the readable ceiling. Mutation lists intersect that set and cannot widen it.

Default create and update inputs stay the current assignable column set, including timestamps. Changing that default would break clients.

ResourceQueryProxy#build_new still permits graphql_assignable_attribute_names so a resolve_create hook can set server-owned readable columns. The GraphQL input type and the mutation resolver slice use the mutation lists.

## Effects

Request spec spec/requests/graphql_mutation_allowlists_spec.rb failed first: six examples raised NoMethodError on the new DSL. Default examples passed and showed PostCreateInput includes created_at, updated_at, and starred, and that create_post persists a client-supplied created_at of 2020-01-02T03:04:05Z.

After the implementation that spec file: 8 examples, 0 failures (bundle exec rspec spec/requests/graphql_mutation_allowlists_spec.rb).

Claims from the downstream dependency note, checked in this tree at version 0.2.1:

1. Gem version is 0.2.1. Source: lib/active_admin/graphql/version.rb VERSION = "0.2.1". Outcome: supported.
2. Generated create and update inputs expose every assignable database column. Source: ActiveAdmin::Resource#default_attributes walks resource_class.columns minus primary key, STI, counter cache, and application filter_attributes (encrypted_password, password, password_confirmation). SchemaBuilder TypesInputs used graphql_assignable_attribute_names for both input types. Dummy PostCreateInput in the new spec includes title, body, starred, created_at, updated_at. Outcome: supported for ActiveAdmin resource_attributes, not every SQL column in the abstract (filtered password columns stay out).
3. The package mutations therefore accepted calculated values and internal timestamps that the server owns. Source: the same spec persisted created_at on create. Package column names (budget status, velocity, usage totals) are not in this repository. Outcome: supported for timestamps on Post; unverifiable for named Package columns.
4. only limits output fields, so it cannot express a mutation-only allowlist without hiding fields from queries. Source: attributes_for_graphql applies only_attributes and exclude_attributes; types_object and graphql_assignable_attribute_names both use that list. Outcome: supported.
5. The schema builder derives both mutation inputs from graphql_assignable_attribute_names and provides no separate create or update configuration. Source: types_inputs.rb before this change; ResourceConfig had only_attributes and exclude_attributes only. Outcome: supported for 0.2.1; outdated after RFC 0006 ships.
6. The application resolves the gem from its published package and records it in Gemfile.lock. Source: not this repository. Outcome: unverifiable here.

## Next

Keep RFC 0006 Proposed until 2026-10-05 lazy consensus. 0.3.0 metadata includes the graphql 2.6.9 floor and ActiveAdmin 4 Rails 8 matrix; tag and gem push wait on make release.

Later pass 2026-09-21: DSL renamed to ActiveAdmin permit_params with nested create and update blocks. create_only, update_only, assignable, and except_assignable were dropped before release. Spec path is spec/requests/graphql_mutation_permit_params_spec.rb. RFC file is rfcs/0006-mutation-permit-params.md. Default mutation inputs omit created_at and updated_at.

## Source

Downstream dependency note that described PackageCreateInput. RFC 0004. lib/active_admin/graphql/integration.rb. lib/active_admin/graphql/schema_builder/types_inputs.rb. vendor activeadmin-3.5.2 lib/active_admin/resource/attributes.rb and application_settings.rb filter_attributes. spec/requests/graphql_mutation_allowlists_spec.rb.
