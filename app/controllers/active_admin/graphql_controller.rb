# frozen_string_literal: true

module ActiveAdmin
  # HTTP endpoint for the namespace GraphQL schema (graphql-ruby).
  #
  # Authentication runs before any GraphQL work, including introspection.
  # Supports single operations (+application/json+ body or form params) and
  # multiplexed batches (+application/json+ array documented by graphql-ruby).
  class GraphqlController < ApplicationController
    protect_from_forgery with: :exception

    before_action :ensure_graphql_enabled!
    before_action :authenticate_graphql!

    def execute
      schema = ActiveAdmin::GraphQL.schema_for(active_admin_namespace)

      if multiplex_request?
        operations = multiplex_operations
        max_n = active_admin_namespace.graphql_multiplex_max || 20
        if operations.size > max_n
          return render json: {errors: [{message: "Multiplex exceeds maximum of #{max_n}"}]},
            status: :content_too_large
        end

        results = schema.multiplex(
          operations.map do |op|
            {
              query: op[:query],
              variables: ensure_variables(op[:variables]),
              operation_name: op[:operation_name],
              context: graphql_context
            }
          end
        )
        render json: results.map(&:to_h), status: :ok
      else
        result = schema.execute(
          query: query_string,
          variables: ensure_variables(variables_hash),
          operation_name: operation_name,
          context: graphql_context
        )
        render json: result.to_h, status: :ok
      end
    end

    def active_admin_namespace
      key = request.path_parameters[:active_admin_namespace] || params[:active_admin_namespace]
      raise ActionController::RoutingError, "Missing active_admin_namespace route default" unless key

      ActiveAdmin.application.namespaces[key.to_sym].tap do |ns|
        raise ActionController::RoutingError, "Unknown ActiveAdmin namespace: #{key}" unless ns
      end
    end

    private

    def ensure_graphql_enabled!
      return if active_admin_namespace.graphql
      head :not_found and return
    end

    def authenticate_graphql!
      meth = active_admin_namespace.authentication_method
      send(meth) if meth
    end

    def current_active_admin_user
      meth = active_admin_namespace.current_user_method
      send(meth) if meth
    end

    def graphql_context
      ns = active_admin_namespace
      {
        auth: ActiveAdmin::GraphQL::AuthContext.new(
          user: current_active_admin_user,
          namespace: ns
        ),
        namespace: ns,
        request: request,
        current_user: current_active_admin_user,
        visibility_profile: graphql_visibility_profile_for(ns)
      }.compact
    end

    def graphql_visibility_profile_for(ns)
      prof = ns.graphql_visibility_profile
      return nil if prof.blank?

      prof.to_sym
    end

    def multiplex_request?
      request.post? && raw_operation_array
    end

    def raw_operation_array
      parsed = request_body_json
      return parsed if parsed.is_a?(Array)

      params[:_json] if params[:_json].is_a?(Array)
    end

    def multiplex_operations
      raw_operation_array.map { |payload| normalize_operation(payload) }
    end

    def normalize_operation(payload)
      h = payload.stringify_keys
      {
        query: h["query"],
        variables: h["variables"],
        operation_name: h["operationName"] || h["operation_name"]
      }
    end

    def query_string
      params[:query] || request_body_hash&.dig("query")
    end

    def operation_name
      params[:operationName] || params[:operation_name] || request_body_hash&.dig("operationName")
    end

    def variables_hash
      params[:variables] || request_body_hash&.dig("variables")
    end

    def request_body_hash
      json = request_body_json
      json if json.is_a?(Hash)
    end

    def request_body_json
      return @request_body_json if defined?(@request_body_json)

      @request_body_json =
        if request.body.nil?
          nil
        else
          body = request.body.read
          request.body.rewind
          body.present? ? JSON.parse(body) : nil
        end
    rescue JSON::ParserError
      @request_body_json = nil
    end

    def ensure_variables(raw)
      case raw
      when String
        raw.present? ? JSON.parse(raw) : {}
      when Hash
        raw
      when ActionController::Parameters
        raw.to_unsafe_h
      when nil
        {}
      else
        {}
      end
    rescue JSON::ParserError
      {}
    end
  end
end
