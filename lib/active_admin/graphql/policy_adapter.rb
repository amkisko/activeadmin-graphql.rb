# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Builds +activeadmin_policies+ payloads for a namespace.
    #
    # Set +graphql_policy_adapter+ to this class (default), another subclass, or a
    # constant name +String+. Omit policy fields with +graphql_policies_enabled = false+.
    class PolicyAdapter
      POLICY_ACTIONS = {
        read: ActiveAdmin::Authorization::READ,
        create: ActiveAdmin::Authorization::CREATE,
        update: ActiveAdmin::Authorization::UPDATE,
        destroy: ActiveAdmin::Authorization::DESTROY
      }.freeze

      attr_reader :namespace

      def initialize(namespace:)
        @namespace = namespace
      end

      # Whether this resource gets an object +activeadmin_policies+ field and a
      # row in the +activeadmin_policies+ resources matrix.
      def include_resource?(aa_resource)
        aa_resource.graphql_config.policies_enabled
      end

      def policy_set(auth:, subject_owner:, subject:, context:)
        base = {
          allowed_actions: allowed_base_actions(
            auth: auth,
            subject_owner: subject_owner,
            subject: subject,
            context: context
          ),
          allowed_member_actions: [],
          allowed_collection_actions: [],
          allowed_batch_actions: []
        }

        append_resource_action_names!(base, auth: auth, subject_owner: subject_owner, subject: subject)

        if (extra = namespace.graphql_policy_extra).respond_to?(:call)
          out = extra.call(context, subject_owner, subject, base)
          base = out if out.is_a?(Hash)
        end
        if (transform = namespace.graphql_policy_transform).respond_to?(:call)
          out = transform.call(context, subject_owner, subject, base)
          base = out if out.is_a?(Hash)
        end
        base
      end

      private

      def policy_action_pairs
        hook = namespace.graphql_policy_actions
        if hook.respond_to?(:call)
          raw = hook.call(namespace)
          return raw.to_h.transform_keys(&:to_sym) if raw.respond_to?(:to_h)
        end
        POLICY_ACTIONS
      end

      def allowed_base_actions(auth:, subject_owner:, subject:, context:)
        action_mapper = namespace.graphql_policy_action_mapper
        policy_action_pairs.each_with_object([]) do |(name, default_action), out|
          allowed = if action_mapper.respond_to?(:call)
            action_mapper.call(context, subject_owner, subject, name, default_action)
          else
            auth.authorized?(subject_owner, default_action, subject)
          end
          out << name.to_s if allowed
        end
      end

      def append_resource_action_names!(base, auth:, subject_owner:, subject:)
        return unless subject_owner.is_a?(ActiveAdmin::Resource)

        class_subject = subject_owner.resource_class
        if subject.is_a?(Class)
          return unless auth.authorized?(subject_owner, ActiveAdmin::Authorization::READ, class_subject)

          base[:allowed_member_actions] = subject_owner.member_actions.map { |a| a.name.to_s }
          base[:allowed_collection_actions] = subject_owner.collection_actions.map { |a| a.name.to_s }
          base[:allowed_batch_actions] = subject_owner.batch_actions.map { |a| a.sym.to_s }
        elsif auth.authorized?(subject_owner, ActiveAdmin::Authorization::READ, subject)
          base[:allowed_member_actions] = subject_owner.member_actions.map { |a| a.name.to_s }
        end
      end
    end
  end
end
