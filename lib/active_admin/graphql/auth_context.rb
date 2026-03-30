# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Authorization adapter wrapper for GraphQL +context+.
    class AuthContext
      attr_reader :user, :namespace

      def initialize(user:, namespace:)
        @user = user
        @namespace = namespace
        @adapter_by_resource_id = {}
      end

      def adapter_for(aa_resource)
        @adapter_by_resource_id[aa_resource.object_id] ||= begin
          klass = namespace.authorization_adapter
          klass = klass.constantize if klass.is_a?(String)
          klass.new(aa_resource, user)
        end
      end

      def authorized?(aa_resource, action, subject = nil)
        adapter_for(aa_resource).authorized?(action, subject)
      end

      # Delegates to the namespace authorization adapter. Built-in resolvers scope
      # collections through +ResourceController+ instead of calling this; it remains
      # available for custom schema extensions or host-app glue code.
      def scope_collection(aa_resource, relation, action = ActiveAdmin::Authorization::READ)
        adapter_for(aa_resource).scope_collection(relation, action)
      end
    end
  end
end
