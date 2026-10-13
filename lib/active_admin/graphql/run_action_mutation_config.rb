# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Pairs return type and optional resolver for one run-action mutation kind (+batch+, +member+,
    # or +collection+). Default return type resolution falls back to {ResourceConfig#run_action_payload_type},
    # then {RunActionPayload}.
    class RunActionMutationConfig
      # @return [Class, nil] +GraphQL::Schema::Object+ subclass
      attr_accessor :payload_type
      # @return [Proc, nil]
      attr_accessor :resolve_proc
      # Optional block evaluated in the graphql-ruby +field+ DSL context (+argument+, …) for per-action fields.
      attr_accessor :arguments_proc
      # Optional authorization toggle for this mutation configuration. +nil+ means namespace default.
      attr_accessor :authorize
      # When true, inject +dry_run+ and honor +preview+ (RFC 0010).
      attr_accessor :dry_run
      # @return [Proc, nil] preview block for dry-run / refuse-before-run
      attr_accessor :preview_proc
      # @return [Array<String>, nil] allowlisted extra GraphQL kwargs forwarded into AA params
      attr_accessor :extra_param_keys
      # Optional capability override for this action field (RFC 0012).
      attr_accessor :capability

      def self.ensure_graphql_object_subclass!(type)
        unless type.is_a?(Class) && type < ::GraphQL::Schema::Object
          raise ArgumentError, "Expected a GraphQL::Schema::Object subclass, got #{type.inspect}"
        end
      end
    end
  end
end
