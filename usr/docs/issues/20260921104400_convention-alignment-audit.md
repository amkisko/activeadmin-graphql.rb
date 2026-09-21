# Convention alignment engineering audit

## Participants

Andrei Makarov

## Decisions

Mutation write lists use ActiveAdmin permit_params. Per-operation lists live in nested create and update blocks with graphql-ruby resolve pairing, matching member_action_mutation. create_only, update_only, assignable, except_assignable, and unassignable are not in the public DSL.

Empty GraphQL input objects call has_no_arguments(true) so graphql-ruby 2.6 does not warn toward a future raise.

HTML permit_params is copied when the HTML call is a static argument list. A request-time block is not copied.

Default mutation inputs omit created_at and updated_at unless listed on permit_params.

destroy_post is registered as an alias of delete_post. graphql_name is an alias of type_name.

Failed save and update raise GraphQL::ExecutionError with extensions.errors. CRUD fields still return the resource object.

GraphqlController logs namespace, operation name, and error_count without the query body or current user.

ResourceMethods lives in lib/active_admin/graphql/resource_methods.rb.

## Effects

First pass used create_only. Second pass replaced it after a convention check against graphql-ruby 2.6.7, Rails 8.1 nested_attributes update_only, upsert_all update_only, and ActiveAdmin 3.5.2 permit_params.

bundle exec rspec spec/requests/graphql_mutation_permit_params_spec.rb: 8 examples, 0 failures after the rename.

## Findings

Severity high. Confidence high. Location SchemaBuilder TypesInputs default create and update inputs. Why it matters: extra-field write of created_at on create, observed in spec/requests/graphql_mutation_permit_params_spec.rb. Evidence kind observed. Security disposition confirmed. Smallest credible fix: graphql { permit_params :title, :body } in the host app. Deeper fix: omit created_at and updated_at from default mutation inputs in a later RFC, matching ActiveAdmin generators/boilerplate.rb assignable_attributes.

Severity medium. Confidence high. Location ResourceDefinitionDSL versus ActiveAdmin::ResourceDSL#permit_params. Why it matters: HTML and GraphQL write lists can drift. Evidence kind observed that GraphQL never calls HTML permit_params. Inference that a static argument list could be copied; confirming check is to parse the controller permitted_params method or store the original args on the resource. Smallest credible fix: document that graphql permit_params should match HTML. Deeper fix: seed GraphQL from a static HTML list when graphql permit_params is unset.

Severity medium. Confidence high. Location mutation_update_destroy.rb delete_ prefix versus actions.include?(:destroy). Why it matters: Rails and ActiveAdmin name the action destroy; GraphQL field is delete_post. Evidence kind observed. Smallest credible fix: none in this RFC; shipped client contract. Deeper fix: RFC to add destroy_* alias or rename.

Severity medium. Confidence high. Location mutation_create.rb returning the record and raising GraphQL::ExecutionError. Why it matters: graphql-ruby Schema::Mutation example returns hash with errors array. Evidence kind observed in graphql-2.6.7 lib/graphql/schema/mutation.rb. Smallest credible fix: none in this RFC. Deeper fix: payload type RFC.

Severity low. Confidence high. Location ResourceDefinitionDSL#type_name versus graphql-ruby graphql_name. Why it matters: two names for the same idea. Evidence kind observed. Smallest credible fix: alias graphql_name. Deeper fix: deprecate type_name after a release.

Severity low. Confidence high. Location ResourceDefinitionDSL#only versus ActiveAdmin action_item only: for controller actions. Why it matters: only already means attribute list in this gem since 0.2.1. Evidence kind observed. Smallest credible fix: keep only; document the split from ActiveAdmin action only.

Severity low. Confidence high. Location GraphqlController, no request correlation log. Why it matters: host logs may not show which GraphQL operation failed. Evidence kind observed absence of log calls in graphql_controller.rb. Smallest credible fix: none required of a library; host can log. Deeper fix: optional around_action.

Severity low. Confidence high. Location lib/active_admin/graphql/integration.rb line count 176. Why it matters: file is above the 150 line preference. Evidence kind observed. Smallest credible fix: extract ResourceMethods. Not done this pass.

## Next

Findings from the 2026-09-21 audit pass are addressed on this branch except replacing CRUD return types with graphql-ruby payload objects, which would break RFC 0004 field types. Keep RFC 0006 Proposed.

## Source

rfcs/0006-mutation-permit-params.md
spec/requests/graphql_mutation_permit_params_spec.rb
vendor activeadmin-3.5.2 lib/active_admin/resource_dsl.rb permit_params
vendor activerecord-8.1.3.1 lib/active_record/nested_attributes.rb update_only
vendor graphql-2.6.7 lib/graphql/schema/mutation.rb
usr/docs/issues/20260921103000_mutation-attribute-allowlists.md
