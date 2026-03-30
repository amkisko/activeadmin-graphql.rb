# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module TypesInputs
        private

        def define_input_assignable_arguments!(input_class, aa_res, required:)
          model = aa_res.resource_class
          cols_by_name = model.columns.index_by(&:name)
          gassign = aa_res.graphql_assignable_attribute_names.map(&:to_s)
          if (btc = aa_res.belongs_to_config)
            gassign -= [btc.to_param.to_s]
          end

          gassign.each do |name|
            col = cols_by_name[name]
            next unless col

            gql_t = graphql_scalar_for_column(aa_res, model, col)
            input_class.argument(name.to_sym, gql_t, required: required, camelize: false)
          end
        end

        def build_create_input_type(aa_res)
          model = aa_res.resource_class
          gname = graphql_type_name_for(aa_res)
          btc = aa_res.belongs_to_config
          builder = self

          klass = Class.new(::GraphQL::Schema::InputObject) do
            graphql_name "#{gname}CreateInput"
            description "Attributes (and nested route params) for creating #{model.name}"

            builder.send(:define_input_assignable_arguments!, self, aa_res, required: false)

            if btc
              argument btc.to_param.to_sym, ::GraphQL::Types::ID, required: btc.required?, camelize: false
            end
          end
          attach_input_object_visibility!(klass, "#{gname}CreateInput", aa_res, :create_input)
          klass
        end

        def build_update_input_type(aa_res)
          model = aa_res.resource_class
          gname = graphql_type_name_for(aa_res)
          btc = aa_res.belongs_to_config
          builder = self

          klass = Class.new(::GraphQL::Schema::InputObject) do
            graphql_name "#{gname}UpdateInput"
            description "Partial attributes (and nested route params) for updating #{model.name}"

            builder.send(:define_input_assignable_arguments!, self, aa_res, required: false)

            if btc
              argument btc.to_param.to_sym, ::GraphQL::Types::ID, required: false, camelize: false
            end
          end
          attach_input_object_visibility!(klass, "#{gname}UpdateInput", aa_res, :update_input)
          klass
        end

        def build_list_filter_input_type(aa_res)
          gname = graphql_type_name_for(aa_res)
          btc = aa_res.belongs_to_config

          klass = Class.new(::GraphQL::Schema::InputObject) do
            graphql_name "#{gname}ListFilterInput"
            description "Index-style filters for #{aa_res.resource_name} (+scope+, +order+, Ransack +q+, parent ids)."

            argument :scope, ::GraphQL::Types::String, required: false, camelize: false
            argument :order, ::GraphQL::Types::String, required: false, camelize: false
            argument :q, ::GraphQL::Types::JSON, required: false, camelize: false
            if btc
              argument btc.to_param.to_sym, ::GraphQL::Types::ID, required: false, camelize: false
            end
          end
          attach_input_object_visibility!(klass, "#{gname}ListFilterInput", aa_res, :list_filter_input)
          klass
        end

        def build_find_input_type(aa_res)
          gname = graphql_type_name_for(aa_res)
          btc = aa_res.belongs_to_config
          model = aa_res.resource_class
          builder = self

          klass = Class.new(::GraphQL::Schema::InputObject) do
            graphql_name "#{gname}WhereInput"
            description "Primary key (and nested parents) for loading one #{aa_res.resource_name} record."

            if ActiveAdmin::PrimaryKey.composite?(model)
              argument :id, ::GraphQL::Types::ID, required: false, camelize: false,
                description: "JSON object string with all primary keys, e.g. " \
                       "{\"book_code\":\"x\",\"seq\":1}"
              ActiveAdmin::PrimaryKey.ordered_columns(model).each do |col|
                coldef = model.columns_hash[col]
                next unless coldef

                gql_t = builder.send(:graphql_scalar_for_column, aa_res, model, coldef)
                argument col.to_sym, gql_t, required: false, camelize: false
              end
            else
              argument :id, ::GraphQL::Types::ID, required: true, camelize: false
            end
            if btc
              argument btc.to_param.to_sym, ::GraphQL::Types::ID, required: btc.required?, camelize: false
            end
          end
          attach_input_object_visibility!(klass, "#{gname}WhereInput", aa_res, :where_input)
          klass
        end
      end
    end
  end
end
