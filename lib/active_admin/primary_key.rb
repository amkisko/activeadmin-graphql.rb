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
        hash = normalize_composite_input(cols, id_param)
        validate_composite_keys!(cols, hash)
        hash
      end

      def normalize_composite_input(cols, id_param)
        case id_param
        when Hash
          id_param.stringify_keys.slice(*cols)
        when String
          extract_composite_json(cols, id_param)
        when Array
          cols.zip(id_param).to_h
        else
          raise ArgumentError, "unsupported composite id type"
        end
      end

      def extract_composite_json(cols, payload)
        parsed = JSON.parse(payload)
        raise ArgumentError, "composite id must be a JSON object" unless parsed.is_a?(Hash)

        parsed.stringify_keys.slice(*cols)
      end

      def validate_composite_keys!(cols, hash)
        missing = cols - hash.keys
        raise ArgumentError, "composite id missing keys: #{missing.join(", ")}" if missing.any?

        absent = cols.select { |c| hash[c].nil? }
        raise ArgumentError, "composite id missing values for: #{absent.join(", ")}" if absent.any?
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
          single_member_param(blob)
        else
          composite_member_param(model, blob, cols)
        end
      end

      def single_member_param(blob)
        id = blob["id"]
        raise ArgumentError, "id is required" if id.blank?

        {"id" => id.to_s}
      end

      def composite_member_param(model, blob, cols)
        return find_attributes(model, blob["id"]).stringify_keys if blob["id"].present?
        return cols.to_h { |c| [c, blob[c]] } if cols.all? { |c| blob.key?(c) && blob[c].present? }

        raise ArgumentError, "composite id requires id (JSON) or all primary key columns"
      end

      def field_kw_to_param_hash(model, id:, **kw)
        cols = ordered_columns(model)
        if cols.size == 1
          single_field_hash(id)
        else
          composite_field_hash(model, cols, id, kw)
        end
      end

      def single_field_hash(id)
        raise ArgumentError, "id is required" if id.blank?

        {"id" => id.to_s}
      end

      def composite_field_hash(model, cols, id, kw)
        return find_attributes(model, id).stringify_keys if id.present?

        out = cols.to_h { |c| [c, kw[c.to_sym] || kw[c]] }
        return out.transform_values(&:to_s) if cols.all? { |c| !out[c].nil? }

        raise ArgumentError, "composite id requires id (JSON) or all primary key fields as arguments"
      end
    end
  end
end
