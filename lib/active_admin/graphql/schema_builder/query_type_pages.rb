# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module QueryTypePages
        def add_page_query_fields!(query_class, builder:, ns:)
          ns.resources.each do |page|
            next unless page.is_a?(ActiveAdmin::Page)

            page.graphql_fields.each do |spec|
              fname = spec[:name].to_sym
              gql_t = spec[:type]
              null = spec[:null]
              desc = spec[:description]
              resolver = spec[:resolver]

              if gql_t.nil?
                raise ArgumentError,
                  "graphql_field :#{spec[:name]} on page #{page.name.inspect} requires a GraphQL type"
              end

              kwargs = {null: null, camelize: false, visibility: {kind: :query_page_field, field_name: fname.to_s, page: page}}
              kwargs[:description] = desc if desc
              query_class.class_eval do
                field fname, gql_t, **kwargs

                define_method(fname) do
                  auth = context[:auth]
                  unless auth.authorized?(page, ActiveAdmin::Authorization::READ, page)
                    raise ::GraphQL::ExecutionError, "not authorized for page field #{spec[:name]}"
                  end
                  raise ::GraphQL::ExecutionError, "graphql_field :#{spec[:name]} needs a resolver block" unless resolver

                  instance_exec(auth.user, context, &resolver)
                end
              end
            end
          end
        end
      end
    end
  end
end
