# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module MutationActionTypes
        private

        def defined_actions_for(aa_res)
          aa_res.controller.instance_methods.map(&:to_sym) & ActiveAdmin::ResourceController::ACTIVE_ADMIN_ACTIONS
        end

        def run_action_return_type(aa_res, kind)
          cfg = aa_res.graphql_config
          specific = case kind
          when :batch then cfg.batch_run_action.payload_type
          when :member then cfg.member_run_action.payload_type
          when :collection then cfg.collection_run_action.payload_type
          else
            raise ArgumentError, "unknown run-action kind #{kind.inspect}"
          end
          ty = specific || cfg.run_action_payload_type || RunActionPayload
          ensure_run_action_graphql_object!(aa_res, ty)
          ty
        end

        def member_action_return_type(aa_res, action_name)
          per = aa_res.graphql_config.member_action_mutations[action_name.to_s]
          ty = per&.payload_type || aa_res.graphql_config.member_run_action.payload_type ||
            aa_res.graphql_config.run_action_payload_type || RunActionPayload
          ensure_run_action_graphql_object!(aa_res, ty)
          ty
        end

        def collection_action_return_type(aa_res, action_name)
          per = aa_res.graphql_config.collection_action_mutations[action_name.to_s]
          ty = per&.payload_type || aa_res.graphql_config.collection_run_action.payload_type ||
            aa_res.graphql_config.run_action_payload_type || RunActionPayload
          ensure_run_action_graphql_object!(aa_res, ty)
          ty
        end

        def ensure_run_action_graphql_object!(aa_res, ty)
          unless ty.is_a?(Class) && ty < ::GraphQL::Schema::Object
            raise ActiveAdmin::DependencyError,
              "#{aa_res.resource_name} graphql run_action payload type must be a GraphQL::Schema::Object subclass, got #{ty.inspect}"
          end
        end
      end
    end
  end
end
