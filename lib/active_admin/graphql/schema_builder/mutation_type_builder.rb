# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module MutationTypeBuilder
        private

        def build_mutation_type
          mutations = []
          ns = @namespace
          sb = self

          active_resources.each do |aa_res|
            model = aa_res.resource_class
            type_c = @object_types[model]
            next unless type_c

            actions = defined_actions_for(aa_res)

            if actions.include?(:create)
              mutations << mutation_create_field(sb, ns, aa_res, model, type_c)
            end
            if actions.include?(:update)
              mutations << mutation_update_field(sb, ns, aa_res, model, type_c)
            end
            if actions.include?(:destroy)
              mutations << mutation_destroy_field(sb, ns, aa_res, model)
            end

            if aa_res.batch_actions_enabled? && aa_res.batch_actions.any?
              mutations << mutation_batch_field(sb, ns, aa_res)
            end
            mutations.concat(mutation_member_fields(sb, ns, aa_res)) if aa_res.member_actions.any?
            mutations.concat(mutation_collection_fields(sb, ns, aa_res)) if aa_res.collection_actions.any?
          end

          return nil if mutations.empty?

          Class.new(::GraphQL::Schema::Object) do
            field_class ::ActiveAdmin::GraphQL::SchemaField

            graphql_name "Mutation"
            description "ActiveAdmin GraphQL mutations (#{ns.name})"

            mutations.each { |m| class_eval(&m) }
          end
        end
      end
    end
  end
end
