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
        keys = normalized_keys(ids)
        uniq = keys.compact.uniq
        return Array.new(ids.size) { nil } if uniq.empty?

        indexed = load_records(uniq)
        keys.map { |key| key.nil? ? nil : indexed[key] }
      end

      def normalized_keys(ids)
        ids.map do |raw|
          raw.nil? ? nil : ActiveAdmin::PrimaryKey.dataloader_tuple(@model_class, raw)
        end
      end

      def load_records(keys)
        ActiveAdmin::PrimaryKey.composite?(@model_class) ? composite_index(keys) : single_column_index(keys)
      end

      def composite_index(keys)
        records = @model_class.where(@pk => keys).to_a
        records.index_by { |record| ActiveAdmin::PrimaryKey.dataloader_tuple_from_record(record) }
      end

      def single_column_index(keys)
        pk_sym = @pk.to_sym
        records = @model_class.where(pk_sym => keys).to_a
        records.index_by { |record| record.public_send(pk_sym) }
      end
    end
  end
end
