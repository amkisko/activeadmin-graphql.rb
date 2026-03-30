# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
    end
  end
end

require_relative "schema_builder/graph_params"
require_relative "schema_builder/visibility"
require_relative "schema_builder/resources"
require_relative "schema_builder/types_object"
require_relative "schema_builder/types_inputs"
require_relative "schema_builder/wire"
require_relative "schema_builder/query_type_registered"
require_relative "schema_builder/query_type_collection"
require_relative "schema_builder/query_type_member"
require_relative "schema_builder/query_type_pages"
require_relative "schema_builder/query_type"
require_relative "schema_builder/resolvers"
require_relative "schema_builder/mutation_action_types"
require_relative "schema_builder/mutation_type_builder"
require_relative "schema_builder/mutation_create"
require_relative "schema_builder/mutation_update_destroy"
require_relative "schema_builder/mutation_batch"
require_relative "schema_builder/mutation_member"
require_relative "schema_builder/mutation_collection"
require_relative "schema_builder/build"

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      def self.graphql_enum_type_name(type_basename, column_name)
        base = type_basename.to_s.gsub(/[^a-zA-Z0-9_]/, "_").squeeze("_")
        col = column_name.to_s.gsub(/[^a-zA-Z0-9_]/, "_").squeeze("_")
        "#{base.camelize}Enum#{col.camelize(:upper)}"
      end

      def initialize(namespace)
        @namespace = namespace
      end

      include GraphParams
      include Visibility
      include Resources
      include TypesObject
      include TypesInputs
      include Wire
      include QueryType
      include Resolvers
      include MutationActionTypes
      include MutationTypeBuilder
      include MutationCreate
      include MutationUpdateDestroy
      include MutationBatch
      include MutationMember
      include MutationCollection
      include Build
    end
  end
end
