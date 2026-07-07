# Testing

## Commands

Full suite (matches CI: parallel shards via Polyrun):

```bash
make test
```

Lint (RuboCop and RBS):

```bash
make lint
```

Focused runs:

```bash
bundle exec rspec spec/unit/schema_builder_spec.rb
bundle exec rspec spec/requests/graphql_spec.rb
```

See `polyrun.yml`. `make test` runs `hooks.before_suite` before specs.

## Layout

- `spec/unit/` — schema builder, routing, and record source specs
- `spec/requests/` — GraphQL request specs against the dummy Rails app
- `spec/dummy/` — minimal Rails app for ActiveAdmin and GraphQL integration
- `spec/support/` — integration helpers

## Guidelines

- Test GraphQL schema behavior and admin resource exposure, not internal builder steps.
- Use the dummy app for request-level contracts; keep unit specs fast and isolated.
- Add or update specs before bugfixes; run `make lint && make test` before a PR.
- Coverage is enforced in CI via a separate `coverage` job (`POLYRUN_COVERAGE=1`) and in `make release`; threshold in `config/polyrun_coverage.yml`.
