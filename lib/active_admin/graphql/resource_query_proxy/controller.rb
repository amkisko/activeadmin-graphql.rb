# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class ResourceQueryProxy
      module Controller
        private

        def normalize_graph_params(graph_params)
          h = graph_params.respond_to?(:to_unsafe_h) ? graph_params.to_unsafe_h : graph_params.to_h
          h.stringify_keys
        end

        def param_hash_for(action, extra)
          {
            "action" => action,
            "controller" => "active_admin/graphql"
          }.merge(extra.stringify_keys).tap do |h|
            merge_ransack!(h)
            h["scope"] = @graph_params["scope"].to_s if @graph_params["scope"].present?
            h["order"] = @graph_params["order"].to_s if @graph_params["order"].present?
            merge_belongs_to!(h)
          end
        end

        def merge_ransack!(h)
          q = @graph_params["q"]
          return if q.blank? && !@graph_params.key?("q")

          h["q"] = normalize_q(q)
        end

        def normalize_q(q)
          case q
          when Hash
            q.deep_stringify_keys
          when ActionController::Parameters
            q.to_unsafe_h.deep_stringify_keys
          else
            {}
          end
        end

        def merge_belongs_to!(h)
          btc = @aa_resource.belongs_to_config
          return unless btc

          key = btc.to_param.to_s
          val = @graph_params[key]
          h[key] = val.to_s if val.present?
        end

        def stub_controller!(controller, hash)
          user = @user
          params_obj = ActionController::Parameters.new(hash)
          params_obj.permit!

          controller.define_singleton_method(:params) { params_obj }
          controller.define_singleton_method(:current_active_admin_user) { user }
          controller.define_singleton_method(:current_user) { user }
        end

        def normalize_batch_inputs(inputs)
          return {} if inputs.nil?

          case inputs
          when Array
            KeyValuePairs.to_hash(inputs)
          when String
            JSON.parse(inputs)
          when Hash
            inputs
          when ActionController::Parameters
            inputs.to_unsafe_h
          else
            raise ::GraphQL::ExecutionError, "batch inputs must be a list of key/value pairs or a JSON object"
          end.then do |h|
            raise ::GraphQL::ExecutionError, "batch inputs must resolve to a hash" unless h.is_a?(Hash)

            h.deep_stringify_keys
          end
        rescue JSON::ParserError => e
          raise ::GraphQL::ExecutionError, "invalid batch inputs JSON (#{e.message})"
        end

        def normalize_extra_params(extra_params)
          return {} if extra_params.nil?

          if extra_params.is_a?(Array)
            return KeyValuePairs.to_hash(extra_params)
          end

          h = extra_params.respond_to?(:to_unsafe_h) ? extra_params.to_unsafe_h : extra_params.to_h
          h.stringify_keys
        end

        def attach_graphql_request!(controller)
          return if controller.instance_variable_defined?(:@_request) && controller.request

          env = Rack::MockRequest.env_for("http://test.host/", method: "POST", params: {_graphql: "1"})
          req = ActionDispatch::Request.new(env)
          res = ActionDispatch::Response.new
          controller.send(:set_request!, req)
          controller.send(:set_response!, res)
          controller.define_singleton_method(:default_url_options) { {host: "test.host"} }
        end

        def perform_controller_command!(controller)
          attach_graphql_request!(controller)
          yield
          build_run_payload(controller)
        rescue ActiveAdmin::AccessDenied => e
          raise ::GraphQL::ExecutionError, e.message
        end

        def build_run_payload(controller)
          res = controller.response
          RunActionPayload::Result.new(
            ok: true,
            status: res&.status,
            location: extract_location(res),
            body: extract_response_body(res)
          )
        end

        def extract_location(res)
          return nil unless res

          loc = res.location if res.respond_to?(:location)
          loc.presence || res.headers&.[]("Location")
        end

        def extract_response_body(res)
          return nil unless res

          b = res.body
          return nil if b.nil? || (b.respond_to?(:empty?) && b.empty?)

          s = b.is_a?(String) ? b : b.to_s
          s = +s
          s.force_encoding("UTF-8")
          s.valid_encoding? ? s : nil
        rescue
          nil
        end
      end
    end
  end
end
