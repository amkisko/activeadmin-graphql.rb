# Dependency audit 2026-09-21

Full audit: recon, security, freshness, ecosystem. Depth reached: full for hot-path direct packages; GitHub REST rate-limited after activeadmin, graphql-ruby, and ransack so remaining repo strain counts use registry dates, release pages, and fetched repo summaries.

## Participants

Andrei Makarov

## Decisions

Do not bump the whole graph to every registry latest. Hot-path and advisory matches first. Skip ActiveAdmin 4.0.0.beta23, json 3, arbre 2, inherited_resources 2, marcel 2, diff-lcs 2, and net-protocol 0.4. Those majors are either prerelease, pinned by ActiveAdmin 3.5.2, or required by rubocop json ~> 2.3.

Upgrade graphql to 2.6.10 and raise the gemspec floor to >= 2.6.9. That is the only security-driven change from this pass.

Optional same-pass lockfile patches with no major jump: rack 3.2.7, zeitwerk 2.8.3, responders 3.2.1, net-imap 0.6.7, bigdecimal 4.1.3, erb 6.0.7, unicode-display_width 3.3.0, unicode-emoji 4.3.0, polyrun 2.2.4, parallel_tests 5.8.0. rbs 4.2.0, io-console 0.9.4, reline 0.7.0, parallel 2.2.0, sprockets 4.4.1, and rubocop 1.91 sit behind Standard and Rails pins; bump only if those parents allow it.

Keep sqlite3 2.9.6 and json 2.21.2. Those pins already match the 2026-09-07 advisory records.

Stay on ActiveAdmin 3.5.2. It is the latest stable on RubyGems. 4.0.0.beta23 (2026-09-20) is prerelease and pulls arbre ~> 2.0 and inherited_resources ~> 2.0.

Do not reverse the 2026-09-17 choice to keep bundle-audit off test.yml. The on-demand workflow remains the gate. Makefile still has no audit target that mirrors that workflow.

## Effects

ruby-advisory-db update: 1245 advisories, last updated 2026-09-16 10:35:37 -0400, commit 44784c295391577f25d198a9205eae4ba73ec4da.

bundle-audit check failed on all four lockfiles with GHSA-rmxg-5p3r-j6hh (graphql 2.6.7, solution >= 2.6.9). No other scanner matches.

bundle outdated --strict on the root Gemfile listed 16 outdated specs. graphql 2.6.7 vs 2.6.10 is the only outdated hot-path direct runtime gem.

Libyears from Gemfile.lock vs RubyGems stable (compact-graph band: about 10 low, about 100 medium): 124 locked packages, 27 outdated, total lag 17.94 years, average 0.145 years per package, 6 packages one major behind (arbre, inherited_resources, json, marcel, diff-lcs, rubocop-capybara). Coverage floor in config/polyrun_coverage.yml is 85 percent line. No upgrade spike was run this pass.

No person-facing surface in this pass.

## Findings

Tier hot path direct. Kind security. Severity high. Confidence high. Package graphql 2.6.7. Why it matters: Marshal.load of unauthenticated parser cache files is RCE when parse_file runs. Evidence kind observed (bundle-audit, GHSA text, repo grep with no parse_file). Sources: GHSA-rmxg-5p3r-j6hh, ruby-advisory-db. Smallest fix: lock 2.6.10 and gemspec >= 2.6.9. Deeper fix: none. Status: CI graphs affected; this library execute path not_affected. Disposition: upgrade. Next: apply when confirmed.

Tier hot path direct. Kind freshness. Severity low. Confidence high. Package activeadmin 3.5.2 equals RubyGems stable latest (2026-07-13). Why it matters: 4.0.0.beta23 is a different major with arbre 2 and inherited_resources 2. Evidence kind observed (rubygems.org/gems/activeadmin). Watch: stay on 3.5.2 until a stable 4.0. Recon: github.com/activeadmin/activeadmin last push 2026-09-21, 9709 stars, 30 open issues, MIT, not archived.

Tier hot path direct. Kind recon. Severity low. Confidence high. Package graphql locked 2.6.7, latest 2.6.10. Upstream rmosolgo/graphql-ruby last push 2026-09-17, 5445 stars, 63 open issues, MIT. Maintainer cluster: rmosolgo, protocol family graphql-ruby, already the runtime schema engine. Classification healthy. 2.6.10 changelog is patch-level after the 2.6.9 security fix.

Tier hot path transitive. Kind ecosystem. Severity low. Confidence medium. Package kaminari 1.2.2. Why it matters: latest gem is still 1.2.2 from 2021-12-25 while GitHub last push is 2026-02-20 and several June 2026 PRs sit open. ActiveAdmin 3.5.2 and 4.0.0.beta23 still depend on kaminari >= 1.2.1. Evidence kind observed (rubygems version date, github.com/kaminari/kaminari). Watch, not a CVE. Cannot upgrade independently of ActiveAdmin.

Tier hot path transitive. Kind freshness. Severity low. Confidence high. Packages arbre 1.7.0 (latest 2.2.1) and inherited_resources 1.14.0 (latest 2.1.0). Why it matters: ActiveAdmin 3.5.2 pins arbre ~> 1.2 and inherited_resources ~> 1.7. Evidence kind observed (Gemfile.lock activeadmin 3.5.2 dependencies). Do not force majors.

Tier hot path transitive. Kind recon. Severity low. Confidence medium. Package ransack 4.4.1 equals latest (2025-09-29). github.com/activerecord-hackery/ransack last push 2026-05-31, 5860 stars, 156 open issues (about 2.7 percent). Classification healthy. formtastic 6.0.0 equals latest (2026-02-20). has_scope 0.9.0 and jquery-rails 4.6.1 equal latest.

Tier hot path transitive. Kind security. Severity low. Confidence high. Package rack 3.2.6 vs latest 3.2.7. Why it matters: April 2026 Rack CVEs (including GHSA-g2pf-xv49-m2h5 / CVE-2026-34835 and GHSA-h2jq-g4cq-5ppq / CVE-2026-34785) are patched in 3.2.6. 3.2.7 restores Ruby 2.4/2.5 compatibility only. Evidence kind observed (rack changelog 3.2.6 security section, 3.2.7 note). Status: not_affected for those CVEs at 3.2.6. Optional patch bump.

Tier dev/test. Kind freshness. Severity low. Confidence high. json 2.21.2 vs 3.0.2 blocked by rubocop json ~> 2.3. sqlite3 2.9.6 is latest and matches GHSA-mwm8-39rw-8826. rails 8.1.3.1 and 7.2.3.2 match appraisal floors and are current on those lines. appraisal 2.5.0 equals latest (2023-07-14); stale but current.

Tier automation. Kind automation gap. Severity low. Confidence high. Why it matters: Dependabot bundler directory / does not refresh gemfiles/*.gemfile.lock. scorecard.yml still pins actions/checkout 9c091bb (v7.0.0) while test.yml uses 3d3c42e5 (v7.0.1). ossf/scorecard-action 4eaacf05 is v2.4.3; v2.4.4 exists. mschilde/auto-label-merge-conflicts is commented as master. Makefile has no audit target. Evidence kind observed (workflow files, dependabot.yml). Smallest fix: optional action SHA refresh via Dependabot; keep appraisal locks in the on-demand audit. Do not put advisory scanners back on test.yml.

## Next

Wait for a Rails release that includes rails/rails#58601. Then drop the development json < 3 pin and bundle update json. Leave marcel 2 and diff-lcs 2 alone until those parents move.

The standard gem is gone. Lint uses rubocop plus a snapshot of standard 1.56.0 rules.

Optional: align scorecard.yml checkout SHA with v7.0.1.

## Later pass 2026-09-21

This gem is supposed to support ActiveAdmin 4. The first pass skipped the beta. That decision is reversed for the Rails 8 appraisals only.

Decisions: pin ActiveAdmin 4.0.0.beta23 in gemfiles/rails8ruby34.gemfile and gemfiles/rails8ruby4.gemfile. Keep ActiveAdmin ~> 3.5, >= 3.5.2 on rails72. Raise graphql gemspec floor to >= 2.6.9 and lock 2.6.10. Apply the optional patch set. net-protocol 0.4.0 came in with net-imap 0.6.7. json stays 2.21.2.

Rubocop and json 3 path: Standard 1.56.0 (latest, 2026-07-15) depends on rubocop ~> 1.88.0. Locked rubocop 1.88.2 depends on json ~> 2.3, which rejects json 3. RuboCop 1.91.0 depends on json >= 2.3, which allows json 3.0.2. graphql 2.6.8 already dropped quirks_mode for JSON 3. This library uses JSON.parse, JSON.generate, and JSON.dump(hash, buffer). json 3.0.1 restored the dump positional limit argument. Do not add a Gemfile rubocop override that fights Standard.

Effects: bundle-audit check on all four lockfiles: No vulnerabilities found. make lint: 84 files, no offenses, rbs validate ok. bundle exec rspec: 102 examples, 0 failures on the root ActiveAdmin 3.5.2 bundle. BUNDLE_GEMFILE=gemfiles/rails72.gemfile bundle exec rspec: 102 examples, 0 failures. BUNDLE_GEMFILE=gemfiles/rails8ruby34.gemfile and gemfiles/rails8ruby4.gemfile: 102 examples, 0 failures each on ActiveAdmin 4.0.0.beta23. Dummy GraphQL request specs did not need cssbundling-rails or importmap-rails. AA4 HTML asset install is still a host-app concern.

## Later pass 2026-09-21 drop standard

Dropped the standard gem. Locked rubocop 1.91.0. json 3.0.2 failed dummy GraphQL POSTs through Rails JSON.decode. Kept json 2.21.2 with development gemspec json >= 2.21.2, < 3. See usr/docs/changelogs/20260921112800_drop-standard-rubocop-direct.md and usr/docs/dependencies/20260921114000_rails-json-parse-kwargs.md.

## Source

Commands: bundle-audit update; bundle-audit check --gemfile-lock on Gemfile.lock and gemfiles/*.gemfile.lock; bundle outdated --strict; RubyGems /api/v1/gems and /api/v1/versions for locked-vs-latest lag; GitHub REST /repos for activeadmin/activeadmin, rmosolgo/graphql-ruby, activerecord-hackery/ransack.

https://github.com/rmosolgo/graphql-ruby/security/advisories/GHSA-rmxg-5p3r-j6hh
https://rubygems.org/gems/activeadmin
https://rubygems.org/gems/graphql
usr/docs/dependencies/20260921114500_graphql-ghsa-rmxg-5p3r-j6hh.md
usr/docs/dependencies/20260907141000_json-cve-2026-71847.md
usr/docs/dependencies/20260907141000_sqlite3-ghsa-mwm8-39rw-8826.md
usr/docs/dependencies/20260921114000_rails-json-parse-kwargs.md
https://github.com/rails/rails/pull/58601
usr/docs/issues/20260917123253_ci-drop-automatic-dependency-audit.md
usr/docs/issues/20260907141000_engineering-and-dependency-audit.md
