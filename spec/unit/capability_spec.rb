# frozen_string_literal: true

require "rails_helper"

RSpec.describe ActiveAdmin::GraphQL::Capability do
  describe ".normalize_set" do
    it "returns a symbol set and drops blanks" do
      expect(described_class.normalize_set([:pii, "editor", nil, ""])).to eq(Set[:pii, :editor])
    end

    it "returns nil for nil input" do
      expect(described_class.normalize_set(nil)).to be_nil
    end
  end

  describe ".granted?" do
    it "returns true when no capability is required" do
      expect(described_class.granted?({}, nil)).to be(true)
    end

    it "fails closed when a capability is required and context has none" do
      expect(described_class.granted?({}, :pii)).to be(false)
    end

    it "returns true when the capability is present" do
      expect(described_class.granted?({capabilities: Set[:pii]}, :pii)).to be(true)
    end

    it "returns false when the capability is absent from the set" do
      expect(described_class.granted?({capabilities: Set[:editor]}, :pii)).to be(false)
    end
  end
end
