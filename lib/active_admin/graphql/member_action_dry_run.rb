# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Preview context and resolve helpers for +member_action_mutation dry_run:+ (RFC 0010).
    class MemberActionDryRun
      PreviewContext = RunActionPreview

      def self.resolve(
        aa_res,
        proxy:,
        context:,
        action:,
        id:,
        params_h:,
        extras:,
        per:,
        dry_run:
      )
        new(aa_res, proxy:, context:, action:, id:, params_h:, extras:, per:, dry_run:).call
      end

      def initialize(aa_res, proxy:, context:, action:, id:, params_h:, extras:, per:, dry_run:)
        @aa_res = aa_res
        @proxy = proxy
        @context = context
        @action = action
        @id = id
        @params_h = params_h
        @extras = extras
        @per = per
        @dry_run = dry_run
      end

      def call
        record = @proxy.find_member(@id)
        preview_result = run_preview(record)

        if @dry_run
          result = preview_result || default_dry_run_result(record)
          audit!(result, dry_run: true)
          return result
        end

        if preview_result && !preview_result.ok
          audit!(preview_result, dry_run: false)
          return preview_result
        end

        result = run_action
        audit!(result, dry_run: false)
        result
      end

      private

      def run_preview(record)
        return nil unless @per.preview_proc

        PreviewContext.new.instance_exec(
          record,
          proxy: @proxy,
          context: @context,
          aa_resource: @aa_res,
          auth: @context[:auth],
          action: @action,
          id: @id,
          params: @params_h,
          **@extras,
          &@per.preview_proc
        )
      end

      def default_dry_run_result(record)
        body = if record
          "would_run:#{@action}:#{record.id}"
        else
          "would_run:#{@action}"
        end
        RunActionPayload::Result.new(ok: true, status: 200, location: nil, body: body)
      end

      def run_action
        resolve = @per.resolve_proc || @aa_res.graphql_config.member_run_action.resolve_proc
        if resolve
          resolve.call(
            proxy: @proxy,
            context: @context,
            aa_resource: @aa_res,
            auth: @context[:auth],
            action: @action,
            id: @id,
            params: @params_h,
            **@extras
          )
        else
          @proxy.run_member_action(@action, @id, extra_params: @params_h)
        end
      end

      def audit!(result, dry_run:)
        hook = @context[:namespace]&.graphql_run_action_audit
        return if hook.nil?

        hook.call(
          @context,
          {
            action: @action,
            id: @id,
            status: result.respond_to?(:status) ? result.status : nil,
            dry_run: dry_run,
            ok: result.respond_to?(:ok) ? result.ok : nil,
            reason: result.respond_to?(:body) ? result.body : nil
          }
        )
      rescue
        nil
      end
    end
  end
end
