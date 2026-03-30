# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module Resources
        private

        def namespace_resources
          @namespace.resources.select { |r| r.is_a?(ActiveAdmin::Resource) }
        end

        def active_resources
          namespace_resources.select do |r|
            next false if r.graphql_config.disabled?
            next false unless r.resource_class < ActiveRecord::Base

            true
          end
        end

        def graphql_type_name_for(aa_res)
          aa_res.graphql_config.graphql_type_name.presence ||
            aa_res.resource_class.name.delete_prefix("::").gsub("::", "__")
        end

        def attributes_for(aa_res)
          aa_res.attributes_for_graphql
        end

        def configure_schema_plugins(schema)
          if (c = @namespace.graphql_max_complexity)
            schema.max_complexity(c)
          end
          if (d = @namespace.graphql_max_depth)
            schema.max_depth(d)
          end
          if (ps = @namespace.graphql_default_page_size)
            schema.default_page_size(ps)
          end
          if (mps = @namespace.graphql_default_max_page_size)
            schema.default_max_page_size(mps)
          end
        end
      end
    end
  end
end
