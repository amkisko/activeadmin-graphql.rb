# frozen_string_literal: true

# Test-only adapter: allows class-level Post checks, denies Post instances.
# Used to prove member resolve does not distinguish missing from forbidden rows.
module ActiveAdmin
  module GraphQLSpecSupport
    class DenyPostRecordAuthorizationAdapter < ActiveAdmin::AuthorizationAdapter
      def authorized?(action, subject = nil)
        return true if subject.nil?
        return false if subject.is_a?(Post)

        true
      end
    end
  end
end
