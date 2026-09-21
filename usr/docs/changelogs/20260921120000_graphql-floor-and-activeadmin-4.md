## Participants

Andrei Makarov

## Decisions

Raise the published graphql-ruby floor from >= 2.3 to >= 2.6.9 so consumers cannot resolve GHSA-rmxg-5p3r-j6hh. Lock graphql 2.6.10.

Pin ActiveAdmin 4.0.0.beta23 on the Rails 8 appraisal gemfiles. Keep ActiveAdmin 3.5.2 on Rails 7.2 and on the root Gemfile.lock. Hosts must pin the ActiveAdmin 4 prerelease themselves.

Apply patch-level lockfile updates: rack 3.2.7, zeitwerk 2.8.3, responders 3.2.1, net-imap 0.6.7, net-protocol 0.4.0 (with net-imap), bigdecimal 4.1.3, erb 6.0.7, unicode-display_width 3.3.0, unicode-emoji 4.3.0, polyrun 2.2.4, parallel_tests 5.8.0, sprockets 4.4.1, rbs 4.2.0, parallel 2.2.0, io-console 0.9.4, reline 0.7.0.

Leave json 2.21.2. Standard 1.56.0 still pins rubocop ~> 1.88.0, which pins json ~> 2.3.

## Effects

bundle-audit check --gemfile-lock on Gemfile.lock, gemfiles/rails72.gemfile.lock, gemfiles/rails8ruby34.gemfile.lock, and gemfiles/rails8ruby4.gemfile.lock: No vulnerabilities found.

make lint: bundle exec rubocop, 84 files inspected, no offenses detected. bundle exec rbs validate succeeded.

bundle exec rspec: 102 examples, 0 failures (ActiveAdmin 3.5.2). BUNDLE_GEMFILE=gemfiles/rails72.gemfile bundle exec rspec: 102 examples, 0 failures. BUNDLE_GEMFILE=gemfiles/rails8ruby34.gemfile bundle exec rspec: 102 examples, 0 failures (ActiveAdmin 4.0.0.beta23). BUNDLE_GEMFILE=gemfiles/rails8ruby4.gemfile bundle exec rspec: 102 examples, 0 failures (ActiveAdmin 4.0.0.beta23).

CHANGELOG Unreleased names the graphql floor and the ActiveAdmin 4 test matrix. Lockfile-only patches stay out of CHANGELOG.md.

## Next

Wait for a Rails release that includes rails/rails#58601 before json 3. The standard gem is no longer in the graph.

## Later pass 2026-09-21

Dropped standard. Locked rubocop 1.91.0. json stayed 2.21.2 because Rails decode still uses positional JSON.parse options. See usr/docs/changelogs/20260921112800_drop-standard-rubocop-direct.md.

## Source

usr/docs/issues/20260921114500_dependency-audit.md
usr/docs/dependencies/20260921114500_graphql-ghsa-rmxg-5p3r-j6hh.md
https://github.com/rmosolgo/graphql-ruby/security/advisories/GHSA-rmxg-5p3r-j6hh
https://github.com/activeadmin/activeadmin/blob/master/UPGRADING.md
https://github.com/standardrb/standard/blob/main/standard.gemspec
