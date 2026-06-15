# frozen_string_literal: true

require_relative "lib/active_admin/graphql/version"

Gem::Specification.new do |spec|
  spec.name = "activeadmin-graphql"
  spec.version = ActiveAdmin::GraphQL::VERSION
  spec.authors = ["Andrei Makarov"]
  spec.email = ["contact@kiskolabs.com"]
  spec.summary = "GraphQL API extension for ActiveAdmin (graphql-ruby)."
  spec.description = "Exposes ActiveAdmin resources and pages as a graphql-ruby schema with an HTTP endpoint per namespace."
  spec.license = "MIT"
  spec.platform = Gem::Platform::RUBY
  spec.required_ruby_version = ">= 3.2"

  repository_url = "https://github.com/amkisko/activeadmin-graphql.rb"

  spec.homepage = repository_url
  spec.metadata = {
    "homepage_uri" => repository_url,
    "source_code_uri" => "#{repository_url}/tree/main",
    "changelog_uri" => "#{repository_url}/blob/main/CHANGELOG.md",
    "documentation_uri" => "#{repository_url}/blob/main/docs/graphql-api.md",
    "bug_tracker_uri" => "#{repository_url}/issues",
    "rubygems_mfa_required" => "true"
  }

  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    %w[
      CHANGELOG.md
      CODE_OF_CONDUCT.md
      CONTRIBUTING.md
      LICENSE.md
      README.md
      activeadmin-graphql.gemspec
    ].select { |f| File.file?(f) } +
      Dir["docs/**/*.md"] +
      Dir["app/**/*.rb"] +
      Dir["lib/**/*.rb"]
  end

  spec.require_paths = ["lib"]

  spec.add_runtime_dependency "activeadmin", ">= 3.2"
  spec.add_runtime_dependency "graphql", ">= 2.3"

  spec.add_development_dependency "appraisal", "~> 2"
  spec.add_development_dependency "bigdecimal"
  spec.add_development_dependency "bundler", ">= 2"
  spec.add_development_dependency "devise", ">= 4.9"
  spec.add_development_dependency "parallel_tests", "~> 5.7"
  spec.add_development_dependency "rails", ">= 6.1"
  spec.add_development_dependency "rspec", "~> 3"
  spec.add_development_dependency "rspec-rails", ">= 6"
  spec.add_development_dependency "rubocop-rails", "~> 2.34"
  spec.add_development_dependency "rubocop-rspec", "~> 3.8"
  spec.add_development_dependency "rubocop-thread_safety", "~> 0.7"
  spec.add_development_dependency "simplecov", "~> 0.22"
  spec.add_development_dependency "sprockets-rails", ">= 3.4"
  spec.add_development_dependency "sqlite3", ">= 1"
  spec.add_development_dependency "standard", "~> 1.52"
  spec.add_development_dependency "standard-custom", "~> 1.0"
  spec.add_development_dependency "standard-performance", "~> 1.8"
  spec.add_development_dependency "standard-rails", "~> 1.5"
  spec.add_development_dependency "standard-rspec", "~> 0.3"
end
