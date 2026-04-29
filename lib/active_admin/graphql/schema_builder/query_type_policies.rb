# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module QueryTypePolicies
        POLICY_ACTIONS = {
          read: ActiveAdmin::Authorization::READ,
          create: ActiveAdmin::Authorization::CREATE,
          update: ActiveAdmin::Authorization::UPDATE,
          destroy: ActiveAdmin::Authorization::DESTROY
        }.freeze

        def add_activeadmin_policies_query_field!(query_class, builder:, ns:, aa_by_graphql_type_name:)
          resource_policy_type = Class.new(::GraphQL::Schema::Object) do
            graphql_name "ActiveAdminResourcePolicies"
            field :type_name, ::GraphQL::Types::String, null: false, camelize: false
            field :activeadmin_policies, builder.send(:policy_set_type), null: false, camelize: false
          end

          page_policy_type = Class.new(::GraphQL::Schema::Object) do
            graphql_name "ActiveAdminPagePolicies"
            field :name, ::GraphQL::Types::String, null: false, camelize: false
            field :activeadmin_policies, builder.send(:policy_set_type), null: false, camelize: false
          end

          record_policy_type = Class.new(::GraphQL::Schema::Object) do
            graphql_name "ActiveAdminRecordPolicies"
            field :id, ::GraphQL::Types::ID, null: false, camelize: false
            field :activeadmin_policies, builder.send(:policy_set_type), null: false, camelize: false
          end

          matrix_type = Class.new(::GraphQL::Schema::Object) do
            graphql_name "ActiveAdminPolicies"
            field :resources, [resource_policy_type], null: false, camelize: false
            field :pages, [page_policy_type], null: false, camelize: false
          end

          query_class.class_eval do
            field :activeadmin_policies, matrix_type, null: false, camelize: false,
              visibility: {kind: :query_activeadmin_policies}

            field :activeadmin_policies_for, [record_policy_type], null: false, camelize: false,
              visibility: {kind: :query_activeadmin_policies_for} do
              argument :type_name, ::GraphQL::Types::String, required: true, camelize: false
              argument :ids, [::GraphQL::Types::ID], required: true, camelize: false
              argument :path, [KeyValuePairInput], required: false, camelize: false
            end

            define_method(:activeadmin_policies) do
              auth = context[:auth]
              resources = builder.send(:active_resources).map do |aa_res|
                {
                  type_name: builder.send(:graphql_type_name_for, aa_res),
                  activeadmin_policies: builder.send(:build_policy_set, auth: auth, subject_owner: aa_res, subject: aa_res.resource_class, context: context)
                }
              end
              pages = ns.resources.select { |r| r.is_a?(ActiveAdmin::Page) }.map do |page|
                {
                  name: page.name,
                  activeadmin_policies: builder.send(:build_policy_set, auth: auth, subject_owner: page, subject: page, context: context)
                }
              end
              {resources: resources, pages: pages}
            end

            define_method(:activeadmin_policies_for) do |type_name:, ids:, path: nil|
              aa_res = aa_by_graphql_type_name[type_name.to_s]
              raise ::GraphQL::ExecutionError, "unknown resource type_name #{type_name.inspect}" unless aa_res

              proxy = ResourceQueryProxy.new(
                aa_resource: aa_res,
                user: context[:auth].user,
                namespace: ns,
                graph_params: KeyValuePairs.to_hash(path)
              )

              ids.map do |id|
                record = proxy.find_member(id.to_s)
                raise ::GraphQL::ExecutionError, "not found" unless record

                {
                  id: id.to_s,
                  activeadmin_policies: builder.send(:build_policy_set, auth: context[:auth], subject_owner: aa_res, subject: record, context: context)
                }
              end
            end
          end
        end

        private

        def policy_action_pairs
          hook = @namespace.graphql_policy_actions
          if hook.respond_to?(:call)
            raw = hook.call(@namespace)
            return raw.to_h.transform_keys(&:to_sym) if raw.respond_to?(:to_h)
          end
          POLICY_ACTIONS
        end

        def allowed_base_actions(auth:, subject_owner:, subject:, context:)
          action_mapper = @namespace.graphql_policy_action_mapper
          policy_action_pairs.each_with_object([]) do |(name, default_action), out|
            allowed = if action_mapper.respond_to?(:call)
              action_mapper.call(context, subject_owner, subject, name, default_action)
            else
              auth.authorized?(subject_owner, default_action, subject)
            end
            out << name.to_s if allowed
          end
        end

        def build_policy_set(auth:, subject_owner:, subject:, context:)
          base = {
            allowed_actions: allowed_base_actions(auth: auth, subject_owner: subject_owner, subject: subject, context: context),
            allowed_member_actions: [],
            allowed_collection_actions: [],
            allowed_batch_actions: []
          }

          if subject_owner.is_a?(ActiveAdmin::Resource)
            class_subject = subject_owner.resource_class
            if subject.is_a?(Class)
              if auth.authorized?(subject_owner, ActiveAdmin::Authorization::READ, class_subject)
                base[:allowed_member_actions] = subject_owner.member_actions.map { |a| a.name.to_s }
                base[:allowed_collection_actions] = subject_owner.collection_actions.map { |a| a.name.to_s }
                base[:allowed_batch_actions] = subject_owner.batch_actions.map { |a| a.sym.to_s }
              end
            elsif auth.authorized?(subject_owner, ActiveAdmin::Authorization::READ, subject)
              base[:allowed_member_actions] = subject_owner.member_actions.map { |a| a.name.to_s }
            end
          end

          if (extra = @namespace.graphql_policy_extra).respond_to?(:call)
            out = extra.call(context, subject_owner, subject, base)
            base = out if out.is_a?(Hash)
          end
          if (transform = @namespace.graphql_policy_transform).respond_to?(:call)
            out = transform.call(context, subject_owner, subject, base)
            base = out if out.is_a?(Hash)
          end
          base
        end
      end
    end
  end
end
