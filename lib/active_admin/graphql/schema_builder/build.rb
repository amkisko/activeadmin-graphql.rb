# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module Build
        def build
          unless defined?(ActiveRecord::Base)
            raise ActiveAdmin::DependencyError, "ActiveAdmin::GraphQL requires ActiveRecord."
          end

          @aa_by_model = {}
          @object_types = {}
          @enum_types = {}
          @create_input_types = {}
          @update_input_types = {}
          @list_filter_input_types = {}
          @find_input_types = {}
          @aa_by_graphql_type_name = {}

          active_resources.each do |aa_res|
            model = aa_res.resource_class
            @aa_by_model[model] = aa_res
            @object_types[model] = build_object_type(aa_res)
            @aa_by_graphql_type_name[graphql_type_name_for(aa_res)] = aa_res
          end

          wire_belongs_to_associations

          active_resources.each do |aa_res|
            model = aa_res.resource_class
            @create_input_types[model] = build_create_input_type(aa_res)
            @update_input_types[model] = build_update_input_type(aa_res)
            @list_filter_input_types[model] = build_list_filter_input_type(aa_res)
            @find_input_types[model] = build_find_input_type(aa_res)
          end

          union_members = @object_types.values.uniq
          registered_resource_union =
            if union_members.any?
              u = Class.new(::GraphQL::Schema::Union) do
                graphql_name "ActiveAdminRegisteredResource"
                description "Any resource object type registered for GraphQL in this namespace."
                possible_types(*union_members)
              end
              attach_registered_resource_union_visibility!(u)
              u
            end

          query_type = build_query_type(registered_resource_union: registered_resource_union)
          mutation_type = build_mutation_type

          model_to_type = @object_types

          schema = Class.new(::GraphQL::Schema)
          schema.query(query_type)
          schema.mutation(mutation_type) if mutation_type
          dataloader_plugin = @namespace.graphql_dataloader || ::GraphQL::Dataloader
          schema.use(dataloader_plugin)
          apply_graphql_visibility!(schema)
          if registered_resource_union
            schema.define_singleton_method(:resolve_type) do |abstract_type, obj, ctx|
              if abstract_type == registered_resource_union
                typ = model_to_type[obj.class]
                unless typ
                  raise ::GraphQL::ExecutionError,
                    "ActiveAdminRegisteredResource could not resolve type for #{obj.class.name}"
                end

                typ
              else
                super(abstract_type, obj, ctx)
              end
            end
          end
          configure_schema_plugins(schema)
          hook = @namespace.graphql_configure_schema
          hook.call(schema) if hook.respond_to?(:call)
          schema
        end
      end
    end
  end
end
