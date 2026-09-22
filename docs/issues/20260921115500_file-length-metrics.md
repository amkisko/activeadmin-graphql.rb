# File length metrics

## Participants

Andrei Makarov

## Decisions

Per-file line count is Metrics/FileLength. RuboCop core does not ship that cop. The local cop counts physical source lines, including blanks and comments.

WarnMax is 150 and reports as info. Max is 300 and reports as error. RuboCop fail-level is refactor, so a warning offense would fail make lint the same as an error. Info is the non-failing warning band. Error is the alert that fails the run.

Class and module length stay at 200 with CountAsOne for array, hash, heredoc, and method_call. That sits between the preferred file size and the file alert. Complexity cops stay at cyclomatic 18, perceived 18, and AbcSize 35.

spec/requests/graphql_spec.rb is over 300 lines. It has a file-level disable until that request matrix is split.

## Effects

bundle exec rspec spec/unit/file_length_cop_spec.rb: 4 examples, 0 failures.

make lint: bundle exec rubocop, 86 files inspected, 5 info Metrics/FileLength offenses, exit 0. bundle exec rbs validate succeeded.

## Next

Split spec/requests/graphql_spec.rb so the disable can drop. Files in the info band at this pass: app/controllers/active_admin/graphql_controller.rb, lib/active_admin/graphql/integration.rb, lib/active_admin/graphql/resource_query_proxy/controller.rb, lib/active_admin/graphql/schema_builder/query_type_policies.rb, spec/requests/graphql_mutation_permit_params_spec.rb.

## Source

.rubocop.yml Metrics/FileLength, Metrics/ClassLength, Metrics/ModuleLength
rubocop/cop/metrics/file_length.rb
spec/unit/file_length_cop_spec.rb
