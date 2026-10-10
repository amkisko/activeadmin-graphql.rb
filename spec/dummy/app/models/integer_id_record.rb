# frozen_string_literal: true

# Fixture table with an `id` column that is not declared as the primary key.
class IntegerIdRecord < ApplicationRecord
  self.primary_key = nil
end
