# frozen_string_literal: true

class LibraryEdition < ApplicationRecord
  self.primary_key = %i[book_code seq]
end
