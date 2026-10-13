# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Shared +ok+ / +refuse+ helpers for run-action preview blocks (RFC 0010, RFC 0013).
    class RunActionPreview
      def ok(body, status: 200)
        RunActionPayload::Result.new(ok: true, status: status, location: nil, body: body.to_s)
      end

      def refuse(body, status: 422)
        RunActionPayload::Result.new(ok: false, status: status, location: nil, body: body.to_s)
      end

      def self.call(preview_proc, **kwargs)
        new.instance_exec(**kwargs, &preview_proc)
      end
    end
  end
end
