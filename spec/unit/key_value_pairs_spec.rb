# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe ActiveAdmin::GraphQL::KeyValuePairs do
  describe ".to_hash" do
    it "returns an empty hash for nil" do
      expect(described_class.to_hash(nil)).to eq({})
    end

    it "converts an array of key/value objects" do
      a = [{"key" => "x", "value" => "1"}, {"key" => "y", "value" => "2"}]
      expect(described_class.to_hash(a)).to eq("x" => "1", "y" => "2")
    end

    it "raises ArgumentError for non-array" do
      expect { described_class.to_hash({}) }.to raise_error(ArgumentError)
    end

    it "raises GraphQL::ExecutionError for a bad entry" do
      expect { described_class.to_hash([{}]) }.to raise_error(::GraphQL::ExecutionError)
    end
  end
end
