# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module QueryType
        include QueryTypeRegistered
        include QueryTypeCollection
        include QueryTypeMember
        include QueryTypePages

        def build_query_type(registered_resource_union:)
          builder = self
          ns = @namespace
          aa_by_model = @aa_by_model
          object_types = @object_types
          aa_by_graphql_type_name = @aa_by_graphql_type_name
          list_filter_input_types = @list_filter_input_types
          find_input_types = @find_input_types

          Class.new(::GraphQL::Schema::Object) do
            field_class ::ActiveAdmin::GraphQL::SchemaField

            graphql_name "Query"
            description "ActiveAdmin GraphQL API (#{ns.name})"

            if registered_resource_union
              builder.add_registered_resource_query_field!(
                self,
                builder: builder,
                ns: ns,
                registered_resource_union: registered_resource_union,
                aa_by_graphql_type_name: aa_by_graphql_type_name
              )
            end

            builder.add_model_query_fields!(
              self,
              builder: builder,
              ns: ns,
              aa_by_model: aa_by_model,
              object_types: object_types,
              list_filter_input_types: list_filter_input_types,
              find_input_types: find_input_types
            )

            builder.add_page_query_fields!(self, builder: builder, ns: ns)
          end
        end
      end
    end
  end
end
