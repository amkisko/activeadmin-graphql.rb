# frozen_string_literal: true

# Test-only authorization adapter: denies checks whose subject is +Post+ or the +Post+ model class.
module ActiveAdmin
  module GraphQLSpecSupport
    class DenyPostAuthorizationAdapter < ActiveAdmin::AuthorizationAdapter
      def authorized?(action, subject = nil)
        return true if subject.nil?
        return false if subject.is_a?(Post)
        return false if subject.is_a?(Class) && subject == Post

        true
      end
    end
  end
end
