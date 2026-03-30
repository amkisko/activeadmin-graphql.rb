# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe ActiveAdmin::GraphQL::RecordSource, "composite PK" do
  describe "#fetch" do
    it "batches LibraryEdition lookups by composite tuple" do
      a = LibraryEdition.create!(book_code: "A", seq: 1, label: "a")
      b = LibraryEdition.create!(book_code: "B", seq: 2, label: "b")

      source = described_class.new(LibraryEdition)
      id_a = ActiveAdmin::PrimaryKey.graphql_id_value(a)
      id_b = ActiveAdmin::PrimaryKey.graphql_id_value(b)

      expect(LibraryEdition).to receive(:where).once.and_call_original

      out = source.fetch([id_a, id_b, id_a, nil])
      expect(out).to eq([a, b, a, nil])
    end
  end
end
