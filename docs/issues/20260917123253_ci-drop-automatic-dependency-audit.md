CI quality failed on a trailing blank line in spec/support/junit_formatter.rb. Test CI also ran bundler-audit or osv-scanner, which fail whenever an advisory lands even when a separate dependency audit already exists.

## Participants

- amkisko

## Decisions

- Drop bundler-audit and security jobs from test.yml so tests no longer wait on advisory freshness.
- Drop the advisory osv-scanner job from test.yml.
- Add dependency-audit.yml with workflow_dispatch only. Do not run it on push, pull request, or schedule.
- Disable osv-scanner in Trunk Check.
- Disable markdownlint MD013 in .markdownlint.yaml. Keep AGENTS.md in Trunk so other markdownlint rules still run.
- Keep lockfile and spec fixes that were already blocking quality or tests.

## Effects

- Test CI runs lint and specs without an advisory gate.
- Trunk Check no longer treats dependency CVEs as a required check.
- On-demand bundler-audit of every Gemfile.lock is available through workflow_dispatch.

## Next

- Run dependency audit on demand when a release or a known advisory needs it.
- Do not reintroduce advisory scanners into test.yml.

## Source

- GitHub Actions test and Trunk Check failures on 2026-09-17
