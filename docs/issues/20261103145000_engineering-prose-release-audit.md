# Engineering, prose, and release audit

## Participants

Andrei Makarov (@amkisko)

## Decisions

- Keep version 0.4.1. Fold audit fixes into the unpublished cut and date the product changelog 2026-11-03.
- Treat member and registered_resource instance-read denials as missing (null), and update/destroy instance denials as not found, so clients cannot enumerate ids from the error message.
- Wrap resolve_create hooks in a nested transaction and run instance create authorization before commit.
- Keep release confirmation EOF as rejection, require a CHANGELOG version heading, and run tests on pull requests to main.
- Leave policy run-action over-reporting, composite find_members N+1, RecordSource unscoped load, and default-open collection filter policy as follow-up work (medium severity, not cut into 0.4.1).

## Effects

Pipeline: GraphQL HTTP ingress -> schema -> resolve -> auth/policy -> ActiveRecord -> JSON egress. Queue, worker, learned-system, and physical plant modes skipped (absent). Resource and identification: gem execute log keeps namespace, operation name, and error count only.

Ranked fixes applied:

1. Member and registered_resource instance-read deny returns null (high, observed).
2. Update and destroy instance deny returns not found (high, observed).
3. resolve_create hook deny rolls back nested transaction (high, observed).
4. Release changelog heading specs and EOF confirmation coverage (medium, observed).
5. ASCII punctuation in README, CHANGELOG, and graphql-api guide (house prose).
6. Docs timestamp trees: Participants handle, Source after Later pass sections.

Checks: rubocop clean on touched files; rspec 197 examples, 0 failures; gem 0.4.1 builds and verifies.

## Next

- Commit the worktree, then run make release for tag and gem push.
- Follow-up: filter PolicyAdapter run-action lists by per-action authorized?; batch composite find_members; scope RecordSource loads; optional default collection query policy.

## Source

docs/reviews/20261103145000_engineering-prose-release-audit.md
CHANGELOG.md section 0.4.1 (2026-11-03)
docs/reviews/20261028_engineering-audit-release-preparation.md
