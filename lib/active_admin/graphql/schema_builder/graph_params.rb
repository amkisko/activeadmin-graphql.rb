# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module GraphParams
        def graph_params_from_field_kwargs(aa_res, scope: nil, q: nil, order: nil, **kw)
          h = {}
          h[:scope] = scope if scope.present?
          h[:q] = q if !q.nil?
          h[:order] = order if order.present?
          merge_belongs_to_kw!(aa_res, kw, h)
        end

        def graph_params_for_mutation(aa_res, kw)
          merge_belongs_to_kw!(aa_res, kw, {})
        end

        def graph_params_from_input(aa_res, input)
          h = {}
          return h if input.nil?

          blob = input.to_h.stringify_keys
          if (btc = aa_res.belongs_to_config)
            k = btc.to_param.to_s
            h[k] = blob[k] if blob.key?(k) && blob[k].present?
          end
          h
        end

        def assignable_slice_from_input(aa_res, input)
          blob = input.to_h.stringify_keys
          names = aa_res.graphql_assignable_attribute_names.map(&:to_s)
          if (btc = aa_res.belongs_to_config)
            names -= [btc.to_param.to_s]
          end
          blob.slice(*names)
        end

        def list_graph_params(aa_res, filter:, scope:, q:, order:, **kw)
          h = graph_params_from_field_kwargs(aa_res, scope: scope, q: q, order: order, **kw)
          return h unless filter

          fh = filter.to_h.stringify_keys
          h["scope"] = fh["scope"] if fh.key?("scope")
          h["order"] = fh["order"] if fh.key?("order")
          h["q"] = fh["q"] if fh.key?("q")
          if (btc = aa_res.belongs_to_config)
            pk = btc.to_param.to_s
            h[pk] = fh[pk] if fh.key?(pk)
          end
          h
        end

        def graph_params_from_find_blob(aa_res, blob)
          h = {}
          if (btc = aa_res.belongs_to_config)
            k = btc.to_param.to_s
            h[k] = blob[k] if blob.key?(k)
          end
          h
        end

        def merge_belongs_to_kw!(aa_res, kw, h)
          if (btc = aa_res.belongs_to_config)
            key = btc.to_param
            val = kw[key] || kw[key.to_s] || kw[key.to_sym]
            h[key] = val if val.present?
          end
          h
        end
      end
    end
  end
end
