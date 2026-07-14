# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe ActiveAdmin::GraphQL do
  around do |example|
    with_resources_during(example) do
      ActiveAdmin.application.namespaces[:admin].graphql = true
      ActiveAdmin.register(Post)
    end
  ensure
    described_class.clear_schema_cache!
  end

  let(:namespace) { ActiveAdmin.application.namespaces[:admin] }

  it "returns the same schema instance on repeated schema_for calls" do
    first = described_class.schema_for(namespace)
    second = described_class.schema_for(namespace)

    expect(second).to equal(first)
  end

  it "returns one schema instance when schema_for runs concurrently" do
    schemas = Queue.new
    threads = Array.new(8) do
      # rubocop:disable ThreadSafety/NewThread -- intentional contention check for SCHEMA_CACHE_MUTEX
      Thread.new { schemas << described_class.schema_for(namespace) }
      # rubocop:enable ThreadSafety/NewThread
    end
    threads.each(&:join)

    collected = []
    collected << schemas.pop until schemas.empty?
    expect(collected.map(&:object_id).uniq.size).to eq(1)
  end
end
