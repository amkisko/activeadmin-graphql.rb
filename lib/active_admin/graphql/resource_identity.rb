# frozen_string_literal: true

require "json"

module ActiveAdmin
  module GraphQL
    # Resolves GraphQL identity columns and id encode/decode for a registered resource.
    # Prefer `graphql { identity ... }` when ActiveRecord has no primary key / id column.
    module ResourceIdentity
      module_function

      def configured?(aa_res)
        aa_res.graphql_config.identity_columns.present?
      end

      def columns(aa_res)
        configured = aa_res.graphql_config.identity_columns
        return configured if configured.present?

        ActiveAdmin::PrimaryKey.columns(aa_res.resource_class)
      end

      def graphql_id_value(aa_res, record)
        cfg = aa_res.graphql_config
        if (encode = cfg.identity_encode_proc)
          return encode.call(record).to_s
        end

        cols = columns(aa_res)
        return ActiveAdmin::PrimaryKey.graphql_id_value(record) unless configured?(aa_res)

        encode_columns(record, cols, cfg.identity_separator)
      end

      def attributes_for_id(aa_res, id)
        cfg = aa_res.graphql_config
        if (decode = cfg.identity_decode_proc)
          return stringify_attrs(decode.call(id))
        end

        cols = columns(aa_res)
        return ActiveAdmin::PrimaryKey.find_attributes(aa_res.resource_class, id) unless configured?(aa_res)

        decode_columns(cols, id, cfg.identity_separator)
      end

      def encode_columns(record, cols, separator)
        if cols.size == 1
          record.public_send(cols.first).to_s
        elsif separator
          cols.map { |c| record.public_send(c) }.join(separator)
        else
          payload = cols.each_with_object({}) { |c, memo| memo[c] = record.read_attribute(c) }
          JSON.generate(payload)
        end
      end

      def decode_columns(cols, id, separator)
        if cols.size == 1
          {cols.first => id.to_s}
        elsif separator
          parts = id.to_s.split(separator, cols.size)
          raise ArgumentError, "identity id segment count mismatch" if parts.size != cols.size

          cols.zip(parts).to_h
        else
          parsed = JSON.parse(id.to_s)
          raise ArgumentError, "composite id must be a JSON object" unless parsed.is_a?(Hash)

          parsed.stringify_keys.slice(*cols)
        end
      end

      def field_kw_to_param_hash(aa_res, id:, **kw)
        return ActiveAdmin::PrimaryKey.field_kw_to_param_hash(aa_res.resource_class, id: id, **kw) unless configured?(aa_res)

        raise ArgumentError, "id is required" if id.blank?

        {"id" => id.to_s}
      end

      def member_param_hash(aa_res, blob)
        return ActiveAdmin::PrimaryKey.member_param_hash(aa_res.resource_class, blob) unless configured?(aa_res)

        blob = blob.stringify_keys
        raise ArgumentError, "id is required" if blob["id"].blank?

        {"id" => blob["id"].to_s}
      end

      def stringify_attrs(hash)
        raise ArgumentError, "identity decode must return a Hash" unless hash.is_a?(Hash)

        hash.stringify_keys.transform_values { |value| value&.to_s }
      end
    end
  end
end
