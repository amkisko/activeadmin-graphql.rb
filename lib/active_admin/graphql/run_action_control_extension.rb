# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Confirm gate and optional preview short-circuit for custom run-action fields (RFC 0013).
    class RunActionControlExtension < ::GraphQL::Schema::FieldExtension
      def resolve(arguments:, context:, object: nil, objects: nil)
        if options[:confirm] && !arguments[:dry_run] && !arguments[:confirm]
          result = RunActionPayload::Result.new(
            ok: false, status: 422, location: nil, body: "confirm_required"
          )
          audit!(context, result, dry_run: false)
          return result
        end

        preview_proc = options[:preview]
        if preview_proc
          preview_result = run_preview(preview_proc, arguments, context)

          if arguments[:dry_run]
            result = preview_result || default_dry_run_result
            audit!(context, result, dry_run: true)
            return result
          end

          if preview_result&.respond_to?(:ok) && !preview_result.ok
            audit!(context, preview_result, dry_run: false)
            return preview_result
          end
        end

        yield(object.nil? ? objects : object, arguments, nil)
      end

      private

      def run_preview(preview_proc, arguments, context)
        kwargs = arguments.respond_to?(:to_h) ? arguments.to_h : arguments
        kwargs = kwargs.merge(context: context)
        RunActionPreview.call(preview_proc, **kwargs.transform_keys(&:to_sym))
      end

      def default_dry_run_result
        RunActionPayload::Result.new(
          ok: true,
          status: 200,
          location: nil,
          body: "would_run:#{field.graphql_name}"
        )
      end

      def audit!(context, result, dry_run:)
        hook = context[:namespace]&.graphql_run_action_audit
        return if hook.nil?

        hook.call(
          context,
          {
            action: field.graphql_name,
            id: nil,
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
