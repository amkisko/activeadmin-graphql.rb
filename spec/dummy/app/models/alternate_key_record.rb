# frozen_string_literal: true

# Fixture model on view alternate_key_records (source id AS row_key).
class AlternateKeyRecord < ApplicationRecord
  self.primary_key = "row_key"
end
