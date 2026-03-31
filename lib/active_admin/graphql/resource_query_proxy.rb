# frozen_string_literal: true

require "rack/mock"
require "stringio"

require_relative "resource_query_proxy/controller"

module ActiveAdmin
  module GraphQL
    # Reuses {ResourceController} data-access behaviour (+scoped_collection+, +find_collection+,
    # +find_resource+, authorization scoping, Ransack, menu scopes, +sorting+, +includes+)
    # so GraphQL list/detail mutations align with the HTML/JSON list and member REST endpoints.
    class ResourceQueryProxy
      include Controller

      def initialize(aa_resource:, user:, namespace:, graph_params: {})
        @aa_resource = aa_resource
        @user = user
        @namespace = namespace
        @graph_params = normalize_graph_params(graph_params)
      end

      def relation_for_index
        controller_for("index").send(:find_collection, except: %i[pagination collection_decorator])
      end

      def find_member(id)
        extra = member_route_params_for_find(id)
        controller_for("show", extra).send(:find_resource)
      end

      def build_new(attributes)
        if missing_required_belongs_to?
          raise ::GraphQL::ExecutionError,
            "#{@aa_resource.belongs_to_config.to_param} is required for nested resource #{@aa_resource.resource_name}"
        end

        c = controller_for("new")
        chain = c.send(:apply_authorization_scope, c.send(:scoped_collection))
        permitted = attributes.stringify_keys.slice(*@aa_resource.graphql_assignable_attribute_names)
        chain.build(permitted)
      end

      def run_batch_action(batch_sym, ids, inputs: {})
        unless @aa_resource.batch_actions_enabled?
          raise ::GraphQL::ExecutionError, "batch actions are disabled for #{@aa_resource.resource_name}"
        end

        inputs = normalize_batch_inputs(inputs)
        extra = {
          "batch_action" => batch_sym.to_s,
          "collection_selection" => Array(ids).map(&:to_s),
          # TruffleRuby freezes JSON's internal "{}" buffer, so Hash#to_json raises FrozenError.
          # Dumping into a dedicated StringIO avoids mutating the shared literal.
          "batch_action_inputs" => dump_batch_inputs(inputs)
        }
        c = controller_for("batch_action", extra)
        perform_controller_command!(c) { c.send(:batch_action) }
      end

      def run_member_action(action_name, id, extra_params: {})
        action_name = action_name.to_s
        unless @aa_resource.member_actions.any? { |a| a.name.to_s == action_name }
          raise ::GraphQL::ExecutionError, "unknown member action #{action_name.inspect}"
        end

        extras = normalize_extra_params(extra_params)
        c = controller_for(action_name, {"id" => id.to_s}.merge(extras))
        perform_controller_command!(c) { c.send(action_name) }
      end

      def run_collection_action(action_name, extra_params: {})
        action_name = action_name.to_s
        unless @aa_resource.collection_actions.any? { |a| a.name.to_s == action_name }
          raise ::GraphQL::ExecutionError, "unknown collection action #{action_name.inspect}"
        end

        extras = normalize_extra_params(extra_params)
        c = controller_for(action_name, extras)
        perform_controller_command!(c) { c.send(action_name) }
      end

      private

      def member_route_params_for_find(id)
        model = @aa_resource.resource_class
        if ActiveAdmin::PrimaryKey.composite?(model)
          attrs = ActiveAdmin::PrimaryKey.find_attributes(model, id)
          tuple = ActiveAdmin::PrimaryKey.ordered_columns(model).map { |c| attrs[c] }
          {"id" => tuple}
        elsif id.is_a?(Hash)
          id.stringify_keys
        else
          {"id" => id.to_s}
        end
      end

      def missing_required_belongs_to?
        btc = @aa_resource.belongs_to_config
        return false unless btc&.required?

        key = btc.to_param.to_s
        val = @graph_params[key] || @graph_params[key.to_sym]
        val.blank?
      end

      def controller_for(action, extra = {})
        c = @aa_resource.controller.new
        h = param_hash_for(action, extra)
        stub_controller!(c, h)
        c
      end

      def dump_batch_inputs(hash)
        buffer = StringIO.new
        JSON.dump(hash, buffer)
        buffer.string
      rescue FrozenError
        JSON.generate(hash)
      end
    end
  end
end
