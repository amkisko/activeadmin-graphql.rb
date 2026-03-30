# frozen_string_literal: true

require_relative "resource_definition_dsl"

module ActiveAdmin
  module GraphQL
    # Hooks graphql configuration and routing into ActiveAdmin when this gem is loaded.
    module Integration
      module_function

      def install!
        return if @installed

        @installed = true
        ActiveAdmin::Application.prepend(ApplicationUnloadClearsGraphQLSchema)
        register_namespace_settings!
        ActiveAdmin::Resource.prepend(ResourceMethods)
        ActiveAdmin::ResourceDSL.prepend(ResourceDSLMethods)
        ActiveAdmin::Page.prepend(PageMethods)
        ActiveAdmin::PageDSL.prepend(PageDSLMethods)
        ActiveAdmin::Router.prepend(RouterMethods)
        register_railtie!
      end

      def register_namespace_settings!
        ns = ActiveAdmin::NamespaceSettings
        ns.register :graphql, false
        ns.register :graphql_path, "graphql"
        ns.register :graphql_multiplex_max, 20
        ns.register :graphql_dataloader, nil
        ns.register :graphql_visibility, nil
        ns.register :graphql_visibility_profile, nil
        ns.register :graphql_schema_visible, nil
        ns.register :graphql_max_complexity, nil
        ns.register :graphql_max_depth, nil
        ns.register :graphql_default_page_size, nil
        ns.register :graphql_default_max_page_size, nil
        ns.register :graphql_configure_schema, nil
      end

      def register_railtie!
        return unless defined?(Rails::Railtie)

        require_relative "railtie"
      end

      # Stale cached schemas keep references to resources/controllers cleared by +unload!+
      # (e.g. specs that reload registrations). Always drop cached schema when AA unloads.
      module ApplicationUnloadClearsGraphQLSchema
        def unload!
          super
          ActiveAdmin::GraphQL.clear_schema_cache!
        end
      end

      module ResourceMethods
        def graphql_config
          @graphql_config ||= ActiveAdmin::GraphQL::ResourceConfig.new
        end

        def attributes_for_graphql
          keys = resource_attributes.keys
          cfg = graphql_config
          if cfg.only_attributes
            keys &= cfg.only_attributes
          end
          keys -= cfg.exclude_attributes
          keys
        end

        def graphql_assignable_attribute_names
          names = attributes_for_graphql.map(&:to_s)
          pk_cols = ActiveAdmin::PrimaryKey.columns(resource_class)
          return names if pk_cols.size > 1

          names - pk_cols
        end
      end

      module ResourceDSLMethods
        def graphql(&block)
          if block
            ActiveAdmin::GraphQL::ResourceDefinitionDSL.new(config.graphql_config).instance_exec(&block)
          end
          config.graphql_config
        end
      end

      module PageMethods
        def graphql_fields
          @graphql_fields ||= []
        end
      end

      module PageDSLMethods
        def graphql_field(field_name, graphql_type, null: true, description: nil, &block)
          config.graphql_fields << {
            name: field_name.to_s,
            type: graphql_type,
            null: null,
            description: description,
            resolver: block
          }
        end
      end

      module RouterMethods
        def apply
          define_root_routes
          define_graphql_routes
          define_resources_routes
        end

        private

        def define_graphql_routes
          namespaces.each do |namespace|
            next unless namespace.graphql

            segment = namespace.graphql_path.to_s.delete_prefix("/").presence || "graphql"
            defaults = {active_admin_namespace: namespace.name}

            if namespace.root?
              router.post segment, controller: "/active_admin/graphql", action: "execute", defaults: defaults
            else
              router.namespace namespace.name, **namespace.route_options.dup do
                router.post segment, controller: "/active_admin/graphql", action: "execute", defaults: defaults
              end
            end
          end
        end
      end
    end
  end
end
