# frozen_string_literal: true

module ActiveAdmin
  module GraphQL
    # Create or update input options set from +graphql { create do … }+ / +update do … }+.
    class MutationInputConfig
      attr_accessor :permit_params_attributes
      attr_accessor :resolve_proc
    end
  end
end
