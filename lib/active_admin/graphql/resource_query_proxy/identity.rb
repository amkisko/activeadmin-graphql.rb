# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class ResourceQueryProxy
      module Identity
        private

        def find_identity_member(controller, model, id)
          attrs = ActiveAdmin::GraphQL::ResourceIdentity.attributes_for_id(@aa_resource, id)
          raise ActiveRecord::RecordNotFound if attrs.blank?

          records = controller.send(:scoped_collection).where(attrs).limit(2).to_a
          raise_ambiguous_id!(model) if records.size > 1

          records.first || raise(ActiveRecord::RecordNotFound)
        end

        def index_records_by_id(relation, model, primary_key)
          if model.primary_key.present?
            return relation.index_by { |record| record.public_send(primary_key).to_s }
          end

          grouped = relation.to_a.group_by { |record| record.public_send(primary_key).to_s }
          if grouped.any? { |_id, matches| matches.size > 1 }
            raise_ambiguous_id!(model)
          end

          grouped.transform_values(&:first)
        end

        def raise_ambiguous_id!(model)
          raise ::GraphQL::ExecutionError, "ambiguous GraphQL id for #{model.name}"
        end
      end
    end
  end
end
