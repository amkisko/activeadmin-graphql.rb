# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe ActiveAdmin::GraphQL::RecordSource do
  describe "#fetch" do
    it "runs a single query and preserves order including duplicates" do
      a = User.create!(first_name: "Dataloader", last_name: "One")
      b = User.create!(first_name: "Dataloader", last_name: "Two")

      source = described_class.new(User)
      expect(User).to receive(:where).once.and_call_original

      out = source.fetch([a.id, b.id, a.id, nil])
      expect(out).to eq([a, b, a, nil])
    end
  end
end
