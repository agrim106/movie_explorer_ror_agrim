class Review < ApplicationRecord
  belongs_to :user
  belongs_to :movie

  # Validations
  validates :rating, presence: true, numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: 10 }
  validates :comment, presence: true, length: { maximum: 500 }
end