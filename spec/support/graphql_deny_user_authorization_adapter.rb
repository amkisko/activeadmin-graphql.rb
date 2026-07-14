# frozen_string_literal: true

# Test-only authorization adapter: denies READ on +User+ records and the +User+ model class.
module ActiveAdmin
  module GraphQLSpecSupport
    class DenyUserReadAuthorizationAdapter < ActiveAdmin::AuthorizationAdapter
      def authorized?(action, subject = nil)
        return true if subject.nil?
        return false if action == ActiveAdmin::Authorization::READ && subject.is_a?(User)
        return false if action == ActiveAdmin::Authorization::READ && subject.is_a?(Class) && subject == User

        true
      end
    end
  end
end
