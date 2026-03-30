# frozen_string_literal: true

# Shim: GraphQL uses composite-PK helpers; upstream ActiveAdmin may not ship this module yet.
unless defined?(ActiveAdmin::PrimaryKey)
  require "json"

  module ActiveAdmin
    module PrimaryKey
      module_function

      def composite?(model)
        pk = model.primary_key
        pk.is_a?(Array) && pk.size > 1
      end

      def ordered_columns(model)
        Array(model.primary_key).map(&:to_s)
      end

      def columns(model)
        ordered_columns(model)
      end

      def composite_attribute_hash(model, id_param)
        cols = ordered_columns(model)
        h =
          case id_param
          when Hash
            id_param.stringify_keys.slice(*cols)
          when String
            parsed = JSON.parse(id_param)
            raise ArgumentError, "composite id must be a JSON object" unless parsed.is_a?(Hash)

            parsed.stringify_keys.slice(*cols)
          when Array
            cols.zip(id_param).to_h
          else
            raise ArgumentError, "unsupported composite id type"
          end

        missing = cols - h.keys
        raise ArgumentError, "composite id missing keys: #{missing.join(", ")}" if missing.any?

        absent = cols.select { |c| h[c].nil? }
        raise ArgumentError, "composite id missing values for: #{absent.join(", ")}" if absent.any?

        h
      end

      def find_attributes(model, id_param)
        cols = ordered_columns(model)
        if cols.size == 1
          {cols.first => id_param}
        else
          composite_attribute_hash(model, id_param)
        end
      end

      def graphql_id_value(record)
        cols = ordered_columns(record.class)
        if cols.size == 1
          record.public_send(cols.first).to_s
        else
          payload = cols.each_with_object({}) { |c, m| m[c] = record.read_attribute(c) }
          JSON.generate(payload)
        end
      end

      def dataloader_tuple(model, raw)
        cols = ordered_columns(model)
        return raw if cols.size == 1

        h = composite_attribute_hash(model, raw)
        cols.map { |c| h[c] }
      end

      def dataloader_tuple_from_record(record)
        ordered_columns(record.class).map { |c| record.read_attribute(c) }
      end

      def member_param_hash(model, blob)
        blob = blob.stringify_keys
        cols = ordered_columns(model)
        if cols.size == 1
          id = blob["id"]
          raise ArgumentError, "id is required" if id.blank?

          {"id" => id.to_s}
        elsif blob["id"].present?
          find_attributes(model, blob["id"]).stringify_keys
        elsif cols.all? { |c| blob.key?(c) && blob[c].present? }
          cols.to_h { |c| [c, blob[c]] }
        else
          raise ArgumentError, "composite id requires id (JSON) or all primary key columns"
        end
      end

      def field_kw_to_param_hash(model, id:, **kw)
        cols = ordered_columns(model)
        if cols.size == 1
          raise ArgumentError, "id is required" if id.blank?

          {"id" => id.to_s}
        elsif id.present?
          find_attributes(model, id).stringify_keys
        else
          out = cols.to_h { |c| [c, kw[c.to_sym] || kw[c]] }
          if cols.all? { |c| !out[c].nil? }
            out.transform_values(&:to_s)
          else
            raise ArgumentError, "composite id requires id (JSON) or all primary key fields as arguments"
          end
        end
      end
    end
  end
end
