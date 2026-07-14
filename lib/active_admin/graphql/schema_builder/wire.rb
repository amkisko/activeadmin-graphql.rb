# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module Wire
        private

        def wire_belongs_to_associations
          @object_types.each do |model, type_class|
            aa_res = @aa_by_model[model]
            next unless aa_res

            model.reflect_on_all_associations(:belongs_to).each do |ref|
              next if ref.polymorphic?
              target = ref.klass
              target_aa_res = @aa_by_model[target]
              next unless @object_types[target]

              field_name = ref.name.to_sym
              fk = ref.foreign_key.to_s

              type_class.field field_name, @object_types[target], null: true, camelize: false

              type_class.define_method(field_name) do
                fk_val = object.public_send(fk)
                next nil if fk_val.nil?

                record = dataloader.with(ActiveAdmin::GraphQL::RecordSource, target).load(fk_val)
                next nil unless record

                auth = context[:auth]
                if target_aa_res && auth &&
                    !auth.authorized?(target_aa_res, ActiveAdmin::Authorization::READ, record)
                  next nil
                end

                record
              end
            end
          end
        end
      end
    end
  end
end
