# Mutation attribute allowlists

## Participants

Andrei Makarov

## Decisions

Ship RFC 0006 as Proposed with running request specs. CHANGELOG Unreleased names the four graphql DSL methods and the RFC number.

## Effects

Consumers can keep query fields such as timestamps and derived columns while listing authored keys on create and update inputs. Default schema is unchanged.

Later pass 2026-09-21: CHANGELOG Unreleased names permit_params and nested create / update, not create_only.

## Next

Release after merge. Downstream apps replace initializer patches with graphql permit_params and keep their introspection regression spec.

## Source

usr/docs/issues/20260921103000_mutation-attribute-allowlists.md
rfcs/0006-mutation-permit-params.md
