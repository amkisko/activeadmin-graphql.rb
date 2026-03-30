# frozen_string_literal: true

class User < ApplicationRecord
  class VIP < self
  end

  has_many :posts, foreign_key: "author_id"
  has_many :articles, class_name: "Post", foreign_key: "author_id"

  def display_name
    "#{first_name} #{last_name}"
  end
end
