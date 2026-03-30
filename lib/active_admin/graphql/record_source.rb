# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Batches +find+ by primary key for belongs_to-style fields (graphql-ruby dataloader).
    class RecordSource < ::GraphQL::Dataloader::Source
      def initialize(model_class)
        @model_class = model_class
        @pk = model_class.primary_key
      end

      def fetch(ids)
        keys = ids.map { |raw| raw.nil? ? nil : ActiveAdmin::PrimaryKey.dataloader_tuple(@model_class, raw) }
        uniq = keys.compact.uniq
        return ids.map { nil } if uniq.empty?

        if ActiveAdmin::PrimaryKey.composite?(@model_class)
          records = @model_class.where(@pk => uniq).to_a
          by_tuple = records.index_by { |r| ActiveAdmin::PrimaryKey.dataloader_tuple_from_record(r) }
          keys.map { |t| t.nil? ? nil : by_tuple[t] }
        else
          pk_sym = @pk.to_sym
          records = @model_class.where(pk_sym => uniq).to_a
          by_id = records.index_by { |r| r.public_send(pk_sym) }
          keys.map { |k| k.nil? ? nil : by_id[k] }
        end
      end
    end
  end
end
