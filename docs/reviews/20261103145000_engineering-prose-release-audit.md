# Engineering and prose audit before 0.4.1 publish

## Participants

Andrei Makarov (@amkisko)

## Decisions

Re-audit main for the unpublished 0.4.1 cut. Include member auth oracle shape, resolve_create transaction order, release confirmation and changelog gates, pull_request CI, and ASCII docs punctuation. Leave tag and RubyGems publish to make release after commit.

## Effects

Pipeline: POST graphql -> GraphqlController#execute -> schema_for -> resolve -> AuthContext / ResourceQueryProxy -> ActiveRecord -> JSON. Boundary mode covered class vs instance authorization messages. Resource and identification modes: no new person identifiers in gem logs. Queue, worker, learned-system, and physical plant modes skipped (absent).

Ranked fixes applied:

1. Null for denied member and registered_resource reads (high confidence, observed).
2. not found for denied update and destroy (high confidence, observed).
3. Nested transaction around resolve_create with instance authorize before commit (high confidence, observed).
4. Changelog heading and confirmation specs; CHANGELOG dated 2026-11-03.
5. ASCII punctuation pass on README, CHANGELOG, and docs/graphql-api.md.

Deferred (documented in the issue): PolicyAdapter run-action over-report, composite find_members N+1, RecordSource unscoped PK load, default-open collection q policy.

Checks observed in this session:

- bundle exec rubocop on touched Ruby files: 9 files, no offenses.
- bundle exec rspec: 197 examples, 0 failures (includes release_version_check and new auth examples).
- gem build activeadmin-graphql.gemspec and Gem::Package#verify for 0.4.1: ok.

## Next

Commit, then make release.

## Source

- docs/issues/20261103145000_engineering-prose-release-audit.md
- CHANGELOG.md section 0.4.1 (2026-11-03)
