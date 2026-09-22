## Participants

Andrei Makarov

## Decisions

Drop the standard gem. Lint stays on rubocop with a snapshot of standard 1.56.0 config/base.yml plus standard-custom, standard-performance, and standard-rails.

Raise the development rubocop floor to ~> 1.91. That gem allows json >= 2.3.

Keep json on 2.21.2. Rails 8.1.3.1 and 7.2.3.2 ActiveSupport::JSON.decode still pass a positional options hash to JSON.parse, which json 3 rejects. Pin development json >= 2.21.2, < 3 until a Rails release includes rails/rails#58601.

## Effects

make lint: bundle exec rubocop, 86 files inspected, 5 Metrics/FileLength info offenses, no failing offenses. bundle exec rbs validate succeeded.

bundle exec rspec: 106 examples, 0 failures on json 2.21.2.

bundle-audit check --gemfile-lock on Gemfile.lock, gemfiles/rails72.gemfile.lock, gemfiles/rails8ruby34.gemfile.lock, and gemfiles/rails8ruby4.gemfile.lock: No vulnerabilities found.

json 3.0.2 in the same graphs made GraphQL request specs fail with Invalid JSON (ParseError wrapping ArgumentError given 2, expected 1). Relocked 2.21.2.

CHANGELOG.md Unreleased was not given a bullet. This is development lint and lockfile work.

## Next

Drop the json < 3 development pin after a Rails release that includes rails/rails#58601, then bundle update json.

## Source

usr/docs/dependencies/20260907141000_json-cve-2026-71847.md
usr/docs/dependencies/20260921114000_rails-json-parse-kwargs.md
usr/docs/issues/20260921114500_dependency-audit.md
https://github.com/standardrb/standard/blob/v1.56.0/config/base.yml
https://github.com/rails/rails/pull/58601
