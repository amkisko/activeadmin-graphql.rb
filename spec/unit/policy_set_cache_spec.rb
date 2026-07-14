# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe ActiveAdmin::GraphQL::PolicySetCache do
  let(:namespace) { ActiveAdmin.application.namespaces[:admin] }
  let(:auth) { ActiveAdmin::GraphQL::AuthContext.new(user: nil, namespace: namespace) }
  let(:context) { {namespace: namespace, auth: auth} }
  let(:aa_resource) { namespace.resource_for(Post) }

  around do |example|
    with_resources_during(example) { ActiveAdmin.register(Post) }
  end

  it "reuses cached policy sets for the same record within a request" do
    post = Post.create!(title: "Cached policy", body: "b")
    first = described_class.fetch(context, subject_owner: aa_resource, subject: post)
    second = described_class.fetch(context, subject_owner: aa_resource, subject: post)

    expect(second).to equal(first)
  end
end
