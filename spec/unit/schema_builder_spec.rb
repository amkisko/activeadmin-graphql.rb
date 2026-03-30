# frozen_string_literal: true

require_relative "../rails_helper"

RSpec.describe ActiveAdmin::GraphQL::SchemaBuilder do
  describe ".graphql_enum_type_name" do
    it "separates pairs that used to camelize to the same GraphQL name" do
      a = described_class.graphql_enum_type_name("User", "notification_channel")
      b = described_class.graphql_enum_type_name("UserNotification", "channel")
      expect(a).to eq("UserEnumNotificationChannel")
      expect(b).to eq("UserNotificationEnumChannel")
      expect(a).not_to eq(b)
    end

    it "handles namespaced model basenames with module separators" do
      name = described_class.graphql_enum_type_name("Admin__User", "status")
      expect(name).to eq("AdminUserEnumStatus")
    end

    it "sanitizes non-alphanumeric characters in basenames and column names" do
      name = described_class.graphql_enum_type_name("Foo-Bar", "kind")
      expect(name).to eq("FooBarEnumKind")
    end

    it "separates basename/column pairs that only differed by an implicit word boundary" do
      # Foo + bar_baz vs FooBar + baz would both have been FooBarBaz with the old rule
      a = described_class.graphql_enum_type_name("Foo", "bar_baz")
      b = described_class.graphql_enum_type_name("FooBar", "baz")
      expect(a).to eq("FooEnumBarBaz")
      expect(b).to eq("FooBarEnumBaz")
      expect(a).not_to eq(b)
    end
  end
end
