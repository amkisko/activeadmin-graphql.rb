# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe ActiveAdmin::GraphQL::PolicySetCache do
  let(:namespace) { ActiveAdmin.application.namespaces[:admin] }
  let(:auth) { ActiveAdmin::GraphQL::AuthContext.new(user: nil, namespace: namespace) }
  let(:context) { {namespace: namespace, auth: auth} }
  let(:aa_resource) { namespace.resource_for(Post) }

  around do |example|
    with_resources_during(example) do
      ActiveAdmin.register(Post)
      ActiveAdmin.register(IntegerIdRecord)
    end
  end

  it "reuses cached policy sets for the same record within a request" do
    post = Post.create!(title: "Cached policy", body: "b")
    first = described_class.fetch(context, subject_owner: aa_resource, subject: post)
    second = described_class.fetch(context, subject_owner: aa_resource, subject: post)

    expect(second).to equal(first)
  end

  it "does not share a policy set between records with the same inferred id" do
    IntegerIdRecord.insert_all!([{id: 42, name: "Alpha"}, {id: 42, name: "Beta"}])
    first_record, second_record = IntegerIdRecord.where(id: 42).to_a
    integer_resource = namespace.resource_for(IntegerIdRecord)
    allow(auth).to receive(:authorized?) do |_resource, _action, subject|
      !subject.respond_to?(:name) || subject.name == "Alpha"
    end

    first = described_class.fetch(context, subject_owner: integer_resource, subject: first_record)
    second = described_class.fetch(context, subject_owner: integer_resource, subject: second_record)

    expect(first.fetch(:allowed_actions)).not_to be_empty
    expect(second.fetch(:allowed_actions)).to be_empty
  end
end
