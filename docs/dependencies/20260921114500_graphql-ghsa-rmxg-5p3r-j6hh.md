## Dependency

- graphql (was 2.6.7, now 2.6.10 in Gemfile.lock and gemfiles/*.gemfile.lock; latest on RubyGems 2.6.10, published 2026-08-27)
- Constraint in this repo: gemspec add_runtime_dependency graphql >= 2.6.9
- Lockfiles: Gemfile.lock, gemfiles/rails72.gemfile.lock, gemfiles/rails8ruby34.gemfile.lock, gemfiles/rails8ruby4.gemfile.lock

## Symptom

bundle-audit matches graphql 2.6.7 against GHSA-rmxg-5p3r-j6hh on every lockfile. Solution text: update to >= 2.6.9.

## Evidence

- Advisory: GraphQL::Language::Cache#fetch reads parser cache files and passes contents to Marshal.load without authenticating payloads. If an attacker can place a crafted file on the expected path and the process calls GraphQL::Language::Parser.parse_file, attacker-controlled marshal_load or _load runs in the process.
- Affected versions: >= 1.12.6. Patched: 2.6.9. Latest registry version 2.6.10 is a later 2.6 patch (dataloader, parser, Execution::Next fixes). No CVE id on the GitHub advisory page as of 2026-09-21.
- This tree has no parse_file, parser_cache, or GraphQL::Language::Cache callers. Schema cache in ActiveAdmin::GraphQL is an in-process class cache, not the parser cache.
- Related older advisory GHSA-j7xr-4g94-r9h3 (Execution::Next authorization bypass) is patched in >= 2.6.6. Lockfiles already sit above that floor. The gemspec floor >= 2.3 still allows those versions for downstream resolvers.

## Suggested fix

Upgrade every lockfile to graphql 2.6.10. Raise the gemspec runtime floor to >= 2.6.9 so consumers cannot resolve the Marshal cache versions. Stay on 2.6; 2.6.10 changelog has no breaking-change heading.

## Trigger

- bundle-audit check against ruby-advisory-db commit 44784c295391577f25d198a9205eae4ba73ec4da (last updated 2026-09-16) during the 2026-09-21 dependency audit.

## Assessment target

- CI and test graphs: Gemfile.lock and appraisal locks.
- Published gem execute path: graphql is a direct runtime dependency. Exploit conditions require Parser.parse_file plus a writable parser cache path.
- Downstream products that resolve this gemspec: unassessed as unnamed consumers.

## Advisory

- GHSA-rmxg-5p3r-j6hh
- CWE-502
- Vendor severity High. bundler-audit criticality Unknown. No CVE. CISA KEV: not listed (no CVE id).
- Related: GHSA-j7xr-4g94-r9h3, patched >= 2.6.6, lockfiles already 2.6.7.

## Status

- CI and test graphs: fixed after lockfiles pin graphql 2.6.10 and the gemspec floor is >= 2.6.9.
- Published gem execute path: not_affected. Vulnerable code not in the execute path of this library or dummy app.

## Applicability

- Vulnerable component present: graphql 2.6.7 is a direct runtime gem.
- Exploit conditions: attacker-controlled parser cache file plus Parser.parse_file. Those APIs are absent from lib/ and spec/.

## Priority

- CI graph: high because bundle-audit fails on every lockfile.
- Published gem execute path: low. This library does not enable the parser cache.
- Downstream resolvers: medium until the gemspec floor moves. Consumers who set config.graphql.parser_cache = true on graphql < 2.6.9 meet the advisory conditions.

## Disposition

- Upgrade. bundle lock --update=graphql on the root Gemfile and each appraisal gemfile. Raise spec.add_runtime_dependency graphql to >= 2.6.9.

## Next

- Keep the gemspec floor at graphql >= 2.6.9. Do not drop it back to 2.3.

## Source

- https://github.com/rmosolgo/graphql-ruby/security/advisories/GHSA-rmxg-5p3r-j6hh
- https://rubysec.com/advisories/GHSA-rmxg-5p3r-j6hh/
- https://github.com/rmosolgo/graphql-ruby/blob/master/CHANGELOG.md (2.6.9 security note, 2.6.10 patch notes)
- https://rubysec.com/advisories/GHSA-j7xr-4g94-r9h3/
- usr/docs/issues/20260921114500_dependency-audit.md
