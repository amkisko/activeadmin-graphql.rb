# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Built-in helpers for +graphql_collection_query_policy+ (RFC 0011).
    module CollectionQueryPolicy
      module_function

      def require_visible_fields!(
        context:,
        aa_resource:,
        q: nil,
        order: nil,
        allow_q_keys: [],
        field_grants: {},
        infer_field_grants: true
      )
        allow = Array(allow_q_keys).map(&:to_s)
        grants = merge_field_grants(aa_resource, field_grants, infer: infer_field_grants)

        normalize_q(q).each_key do |raw_key|
          key = raw_key.to_s
          next if allow.include?(key)

          field_name = field_from_predicate_key(key)
          unless field_name
            raise ::GraphQL::ExecutionError, "unsupported collection filter key #{key.inspect}"
          end

          assert_field_filterable!(context, aa_resource, field_name, grants)
        end

        assert_order_filterable!(context, aa_resource, order, grants) if order.present?
      end

      def merge_field_grants(aa_resource, field_grants, infer: true)
        explicit = field_grants.to_h.transform_keys(&:to_s).transform_values(&:to_sym)
        return explicit unless infer

        inferred = aa_resource.graphql_config.field_capabilities.to_h do |name, capability|
          [name.to_s, capability.to_sym]
        end
        inferred.merge(explicit)
      end

      def normalize_q(q)
        return {} if q.nil?
        return q.to_unsafe_h if q.respond_to?(:to_unsafe_h)

        q.respond_to?(:to_h) ? q.to_h : {}
      end

      def field_from_predicate_key(key)
        predicates = ransack_predicate_names
        predicates.sort_by(&:length).reverse_each do |predicate|
          suffix = "_#{predicate}"
          return key[0...-suffix.length] if key.end_with?(suffix) && key.length > suffix.length
        end
        nil
      end

      def ransack_predicate_names
        if defined?(Ransack) && Ransack.respond_to?(:predicates)
          Ransack.predicates.keys.map(&:to_s)
        else
          %w[eq cont start end gt lt gteq lteq in not_in null present blank matches does_not_match]
        end
      end

      def assert_order_filterable!(context, aa_resource, order, grants)
        column = order.to_s.sub(/_(asc|desc|ascs|descs)\z/i, "")
        return if column.blank?

        assert_field_filterable!(context, aa_resource, column, grants)
      end

      def assert_field_filterable!(context, aa_resource, field_name, grants)
        unless field_schema_visible?(context, aa_resource, field_name)
          raise ::GraphQL::ExecutionError, "not authorized to filter on #{field_name}"
        end

        capability = grants[field_name.to_s]
        return if capability.nil?
        return if Capability.granted?(context, capability)

        raise ::GraphQL::ExecutionError, "not authorized to filter on #{field_name}"
      end

      def field_schema_visible?(context, aa_resource, field_name)
        type_name = graphql_type_name_for(aa_resource)
        type = context.schema.get_type(type_name, context)
        return false unless type

        !context.schema.get_field(type, field_name.to_s, context).nil?
      end

      def graphql_type_name_for(aa_resource)
        aa_resource.graphql_config.graphql_type_name.presence ||
          aa_resource.resource_class.name.delete_prefix("::").gsub("::", "__")
      end
    end
  end
end
