# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    module MutationExecutionError
      module_function

      def validation(record)
        ::GraphQL::ExecutionError.new(
          record.errors.full_messages.to_sentence,
          extensions: {"errors" => record.errors.full_messages}
        )
      end
    end
  end
end
