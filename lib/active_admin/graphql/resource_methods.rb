# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    module Integration
      module ResourceMethods
        SERVER_OWNED_TIMESTAMP_COLUMNS = %w[created_at updated_at].freeze

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

        def graphql_create_attribute_names
          mutation_permit_params_names(
            graphql_config.create_input.permit_params_attributes || graphql_config.permit_params_attributes
          )
        end

        def graphql_update_attribute_names
          mutation_permit_params_names(
            graphql_config.update_input.permit_params_attributes || graphql_config.permit_params_attributes
          )
        end

        private

        def mutation_permit_params_names(permit_list)
          names = graphql_assignable_attribute_names.map(&:to_s)
          permit_list = graphql_config.html_permit_params_attributes if permit_list.nil?
          return names - SERVER_OWNED_TIMESTAMP_COLUMNS if permit_list.nil?

          names & permit_list.map(&:to_s)
        end
      end
    end
  end
end
