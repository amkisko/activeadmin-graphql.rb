# activeadmin-graphql

GraphQL HTTP API for [ActiveAdmin](https://activeadmin.info), built with [graphql-ruby](https://graphql-ruby.org). Register resources as usual, optionally add a `graphql do ... end` block, enable the endpoint per namespace, and get a schema with queries and mutations aligned with ActiveAdmin authorization and filters.

## Setup

```ruby
# Gemfile (graphql-ruby is pulled in by activeadmin-graphql)
gem "activeadmin"
gem "activeadmin-graphql"
```

```ruby
# config/initializers/active_admin.rb
ActiveAdmin.setup do |config|
  config.namespace :admin do |admin|
    admin.graphql = true
    # admin.graphql_path = "graphql" # default: POST /admin/graphql
  end
end
```

Bundler loads this gem as usual; that requires `graphql-ruby` and wires ActiveAdmin routing and DSL for GraphQL.

Documentation: [docs/graphql-api.md](docs/graphql-api.md) covers the endpoint, schema, `graphql do … end`, authorization, composite PKs, visibility, and dataloaders. For an older GraphQL integration, see “Migrating GraphQL clients” in that guide (enum type names, typed mutation inputs, key/value lists vs JSON).

## Development

Tests use a minimal Rails app under `spec/dummy` with SQLite (`:memory:` in test; each [parallel_tests](https://github.com/grosser/parallel_tests) worker is a separate process with its own DB). From the gem root:

```bash
bundle install
bundle exec appraisal install   # generates gemfiles/*.gemfile from Appraisals
bundle exec rubocop
bundle exec parallel_rspec spec # or: bundle exec rspec
# or
rake rubocop
rake spec
```

Matrixed Rails versions use [Appraisal](https://github.com/thoughtbot/appraisal): `gemfiles/rails72.gemfile`, `rails8ruby34.gemfile`, and `rails8truffleruby.gemfile` pin Rails 7.2 / 8.1 (integration tests follow the `spec/dummy` app, which is tested from 7.2 upward). Run `bundle exec appraisal rspec` to execute RSpec in each gemfile context, or `bundle exec parallel_rspec spec` locally for faster multi-process runs on the current bundle.

[Trunk](https://docs.trunk.io) config lives in `.trunk/`; CI runs `trunk` via `.github/workflows/trunk.yml`. Releases: `usr/bin/release.rb` (RuboCop, Appraisal RSpec across gemfiles, `gem build` / `gem push`, git tag, `gh release`).

No local ActiveAdmin checkout is required; the dummy app depends on the published `activeadmin` gem like a normal host app.

## License

MIT — see [LICENSE.md](LICENSE.md).
