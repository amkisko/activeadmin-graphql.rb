# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module TypesObject
        private

        def policy_set_type
          @policy_set_type ||= Class.new(::GraphQL::Schema::Object) do
            graphql_name "ActiveAdminPolicySet"
            description "Allowed ActiveAdmin actions for this subject."

            field :allowed_actions, [::GraphQL::Types::String], null: false, camelize: false
            field :allowed_member_actions, [::GraphQL::Types::String], null: false, camelize: false
            field :allowed_collection_actions, [::GraphQL::Types::String], null: false, camelize: false
            field :allowed_batch_actions, [::GraphQL::Types::String], null: false, camelize: false
            field :extra, ::GraphQL::Types::JSON, null: true, camelize: false
          end
        end

        def build_enum_type(aa_res, column_name, mapping)
          key = [aa_res.resource_class.name, column_name.to_s]
          return @enum_types[key] if @enum_types[key]

          gql_enum_name = self.class.graphql_enum_type_name(graphql_type_name_for(aa_res), column_name)
          enum_class = Class.new(::GraphQL::Schema::Enum) do
            graphql_name gql_enum_name
            description "Rails enum `#{aa_res.resource_class.name}##{column_name}`"

            mapping.each_key do |k|
              value(k.to_s.upcase.gsub(/[^A-Z0-9_]/, "_").squeeze("_"), value: k)
            end
          end
          gql_en = gql_enum_name
          coln = column_name.to_s
          ar = aa_res
          enum_class.define_singleton_method(:visible?) do |ctx|
            hook = ctx[:namespace]&.graphql_schema_visible
            return super(ctx) if hook.nil?

            super(ctx) && !!hook.call(ctx, {kind: :resource_enum, graphql_type_name: gql_en, resource: ar, column: coln})
          end
          @enum_types[key] = enum_class
        end

        def graphql_scalar_for_column(aa_res, model, col)
          if model.defined_enums.key?(col.name)
            return build_enum_type(aa_res, col.name, model.defined_enums[col.name])
          end

          case col.type
          when :integer, :bigint
            ::GraphQL::Types::Int
          when :float, :decimal
            ::GraphQL::Types::Float
          when :boolean
            ::GraphQL::Types::Boolean
          when :datetime, :timestamp
            ::GraphQL::Types::ISO8601DateTime
          when :date
            ::GraphQL::Types::ISO8601Date
          when :json, :jsonb
            ::GraphQL::Types::JSON
          else
            ::GraphQL::Types::String
          end
        end

        def build_object_type(aa_res)
          model = aa_res.resource_class
          gname = graphql_type_name_for(aa_res)
          cols_by_name = model.columns.index_by(&:name)
          attr_names = attributes_for(aa_res).map(&:to_s)

          type_class = Class.new(::GraphQL::Schema::Object) do
            field_class ::ActiveAdmin::GraphQL::SchemaField
            graphql_name gname
            description "ActiveAdmin resource `#{aa_res.resource_name}`"
            implements ::ActiveAdmin::GraphQL::ResourceInterface

            define_singleton_method(:activeadmin_graphql_resource) { aa_res }
          end

          pk_cols = ActiveAdmin::PrimaryKey.columns(model)

          type_class.field :id, ::GraphQL::Types::ID, null: false, authorize: false
          type_class.define_method(:id) { ActiveAdmin::PrimaryKey.graphql_id_value(object) }

          attr_names.each do |name|
            next if pk_cols.include?(name) && pk_cols.size == 1

            col = cols_by_name[name]
            next unless col

            gql_t = graphql_scalar_for_column(aa_res, model, col)
            type_class.field(name.to_sym, gql_t, null: true, camelize: false, authorize: false)

            type_class.define_method(name.to_sym) { object.public_send(name) }
          end

          type_class.field :activeadmin_policies, policy_set_type, null: false, camelize: false, authorize: false
          type_class.define_method(:activeadmin_policies) do
            builder = context[:namespace] && ActiveAdmin::GraphQL::SchemaBuilder.new(context[:namespace])
            builder.send(:build_policy_set, auth: context[:auth], subject_owner: aa_res, subject: object, context: context)
          end

          if (ext = aa_res.graphql_config.extension_block)
            type_class.class_eval(&ext)
          end

          attach_resource_object_visibility!(type_class, gname, aa_res)
          type_class
        end
      end
    end
  end
end
