# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # DSL sugar for custom run-action mutation fields (RFC 0013).
    #
    #   ActiveAdmin::GraphQL::RunActionField.define(schema.mutation, :create_batch,
    #     dry_run: true, confirm: true, capability: :support_act) do
    #     argument :q, GraphQL::Types::JSON, required: true, camelize: false
    #     preview { |**| ok("would_run:create_batch") }
    #     resolve { |q:, **| HostService.call(q: q) }
    #   end
    module RunActionField
      module_function

      def define(
        owner,
        name,
        type: RunActionPayload,
        null: false,
        camelize: false,
        dry_run: false,
        confirm: false,
        capability: nil,
        authorize: false,
        visibility: nil,
        **kwargs,
        &block
      )
        definition = Definition.new
        definition.instance_exec(&block) if block
        unless definition.resolve_proc
          raise ArgumentError, "run_action_field #{name.inspect} requires a resolve block"
        end

        owner.field(
          name,
          type,
          null: null,
          camelize: camelize,
          dry_run: dry_run,
          confirm: confirm,
          preview: definition.preview_proc,
          capability: capability,
          authorize: authorize,
          visibility: visibility,
          **kwargs,
          &definition.field_configuration_block
        )

        resolve_proc = definition.resolve_proc
        owner.define_method(name) do |**args|
          resolve_proc.call(**args)
        end
      end

      # Block body for {RunActionField.define}.
      class Definition
        attr_reader :preview_proc, :resolve_proc

        def initialize
          @argument_calls = []
          @arguments_proc = nil
        end

        def argument(*args, **kwargs)
          @argument_calls << [args, kwargs]
        end

        def arguments(&block)
          @arguments_proc = block
        end

        def preview(&block)
          @preview_proc = block
        end

        def resolve(&block)
          @resolve_proc = block
        end

        def ok(body, status: 200)
          RunActionPreview.new.ok(body, status: status)
        end

        def refuse(body, status: 422)
          RunActionPreview.new.refuse(body, status: status)
        end

        def field_configuration_block
          argument_calls = @argument_calls
          arguments_proc = @arguments_proc
          proc do
            instance_exec(&arguments_proc) if arguments_proc
            argument_calls.each do |args, kwargs|
              argument(*args, **kwargs)
            end
          end
        end
      end
    end
  end
end
