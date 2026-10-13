# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    class SchemaBuilder
      module Resolvers
        def mutation_extra_keyword_params(aa_res, kw, allowlist: nil)
          skip =
            if (btc = aa_res.belongs_to_config)
              [btc.to_param.to_s]
            else
              []
            end
          skip << "id"
          skip << "dry_run"
          allow = allowlist&.map(&:to_s)

          kw.each_with_object({}) do |(key, val), h|
            ks = key.to_s
            next if skip.include?(ks)
            next if allow && !allow.include?(ks)

            h[ks] = val
          end
        end

        def graphql_resolve_index(aa_res, proxy:, context:, graph_params:, **field_kwargs)
          invoke_collection_query_policy!(aa_res, context, field_kwargs)

          proc_ = aa_res.graphql_config.resolve_index_proc
          base_kwargs = {graph_params: graph_params}.merge(field_kwargs)
          if proc_
            proc_.call(proxy: proxy, context: context, aa_resource: aa_res, auth: context[:auth], **base_kwargs)
          else
            proxy.relation_for_index
          end
        end

        def graphql_resolve_show(aa_res, proxy:, context:, id:, graph_params:, **field_kwargs)
          proc_ = aa_res.graphql_config.resolve_show_proc
          base_kwargs = {id: id, graph_params: graph_params}.merge(field_kwargs)
          if proc_
            proc_.call(proxy: proxy, context: context, aa_resource: aa_res, auth: context[:auth], **base_kwargs)
          else
            proxy.find_member(id)
          end
        end

        def graphql_resolve_batch_action(aa_res, proxy:, context:, batch_action:, ids:, inputs:)
          inputs_h = coerce_action_param_map(inputs)
          if (p = aa_res.graphql_config.batch_run_action.resolve_proc)
            p.call(
              proxy: proxy,
              context: context,
              aa_resource: aa_res,
              auth: context[:auth],
              batch_action: batch_action,
              ids: ids,
              inputs: inputs_h
            )
          else
            proxy.run_batch_action(batch_action, ids, inputs: inputs_h)
          end
        end

        def graphql_resolve_member_action(aa_res, proxy:, context:, action:, id:, params: nil, **kw)
          per = aa_res.graphql_config.member_action_mutations[action.to_s]
          dry_run = !!kw[:dry_run]
          extras = mutation_extra_keyword_params(aa_res, kw, allowlist: per&.extra_param_keys)
          params_h = coerce_action_param_map(params).merge(extras.transform_keys(&:to_s))
          params_h.delete("id")

          if per&.dry_run
            return MemberActionDryRun.resolve(
              aa_res,
              proxy: proxy,
              context: context,
              action: action,
              id: id,
              params_h: params_h,
              extras: extras.transform_keys(&:to_sym),
              per: per,
              dry_run: dry_run
            )
          end

          resolve = per&.resolve_proc || aa_res.graphql_config.member_run_action.resolve_proc
          if resolve
            resolve.call(
              proxy: proxy,
              context: context,
              aa_resource: aa_res,
              auth: context[:auth],
              action: action,
              id: id,
              params: params_h,
              **extras.transform_keys(&:to_sym)
            )
          else
            proxy.run_member_action(action, id, extra_params: params_h)
          end
        end

        def graphql_resolve_collection_action(aa_res, proxy:, context:, action:, params: nil, **kw)
          per = aa_res.graphql_config.collection_action_mutations[action.to_s]
          extras = mutation_extra_keyword_params(aa_res, kw, allowlist: per&.extra_param_keys)
          params_h = coerce_action_param_map(params).merge(extras.transform_keys(&:to_s))
          params_h.delete("id")
          resolve = per&.resolve_proc || aa_res.graphql_config.collection_run_action.resolve_proc
          if resolve
            resolve.call(
              proxy: proxy,
              context: context,
              aa_resource: aa_res,
              auth: context[:auth],
              action: action,
              params: params_h,
              **extras.transform_keys(&:to_sym)
            )
          else
            proxy.run_collection_action(action, extra_params: params_h)
          end
        end

        def coerce_action_param_map(value)
          return {} if value.nil?
          return KeyValuePairs.to_hash(value) if value.is_a?(Array)

          h = value.respond_to?(:to_unsafe_h) ? value.to_unsafe_h : value.to_h
          h.stringify_keys
        end

        def invoke_collection_query_policy!(aa_res, context, field_kwargs)
          hook = context[:namespace]&.graphql_collection_query_policy
          return if hook.nil?

          meta = field_kwargs.merge(
            aa_resource: aa_res,
            q: field_kwargs[:q],
            scope: field_kwargs[:scope],
            order: field_kwargs[:order],
            filter: field_kwargs[:filter]
          )
          hook.call(context, meta)
        end

        public :graphql_resolve_index,
          :graphql_resolve_show,
          :graphql_resolve_batch_action,
          :graphql_resolve_member_action,
          :graphql_resolve_collection_action
      end
    end
  end
end
