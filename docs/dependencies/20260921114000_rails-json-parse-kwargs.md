## Dependency

- activesupport / rails (locked 8.1.3.1 on Rails 8 appraisals and the root Gemfile.lock; 7.2.3.2 on rails72)
- json 3.0.2 (RubyGems latest as of 2026-09-09) versus development pin json >= 2.21.2, < 3
- Constraint in this repo: development gemspec only. json is not a runtime gemspec dependency.

## Symptom

With json 3.0.2, dummy GraphQL request specs that POST application/json fail with HTTP 400 and body errors message Invalid JSON. Rails raises ActionDispatch::Http::Parameters::ParseError. The cause is ArgumentError: wrong number of arguments (given 2, expected 1) from JSON.parse.

## Evidence

- json 3.0.0.rc1 (2026-08-11): JSON methods take keyword options, or options checked like keywords. A positional second Hash is no longer accepted by JSON.parse.
- ActiveSupport::JSON.decode in Rails 8.1.3.1 and 7.2.3.2 still calls JSON.parse(json, options) with a positional Hash. ActionDispatch JSON parameter parsing uses that decoder.
- This library's controller uses JSON.parse(body) with one argument. That call works on json 3. The dummy app fails before execute because Rails parses the request first.
- rails/rails#58601 merged 2026-08-28 (commit 0ca2c2c4cfbe7f0a709bca0589d2d74c1853ef27). It is not in 8.1.3.1 or 7.2.3.2.

## Suggested fix

Keep json on 2.21.2 in this repo's lockfiles until a Rails release includes the decode kwargs change. Then drop the development json < 3 pin and bundle update json.

Do not monkeypatch JSON.parse or ActiveSupport::JSON.decode in this library.

## Trigger

- bundle exec rspec after dropping the standard gem and resolving json 3.0.2. 71 request examples failed with Invalid JSON.

## Assessment target

- CI and test graphs: dummy Rails app used by spec/requests.
- Published gem execute path: JSON.parse of the request body with one argument.

## Status

- CI and test graphs: affected on json 3 with Rails 8.1.3.1 and 7.2.3.2. fixed after the development pin json < 3 and lockfiles at 2.21.2.
- Published gem execute path: not_affected for this ArgumentError. The one-argument JSON.parse path does not pass a positional options hash.

## Applicability

- Vulnerable component present: json 3 plus unreleased Rails decode.
- Exploit conditions: not a security advisory. Dummy JSON POST cannot complete parameter parsing.

## Priority

- CI graph: high because request specs fail on every GraphQL POST.
- Published gem execute path: low until a host on json 3 and unpatched Rails hits the same decoder.

## Disposition

- Pin. development gemspec json >= 2.21.2, < 3. Wait for a Rails patch release that includes rails/rails#58601.

## Next

- Watch Rails 8.1 / 7.2 patch notes for the json 3 decode kwargs fix. Then drop the json < 3 development pin and lock json 3.0.2 or newer.

## Source

- https://github.com/rails/rails/pull/58601
- https://github.com/ruby/json/blob/v3.0.2/CHANGES.md
- usr/docs/dependencies/20260907141000_json-cve-2026-71847.md
- usr/docs/issues/20260921114500_dependency-audit.md
