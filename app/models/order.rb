class Order < ApplicationRecord
  belongs_to :user
  belongs_to :movie

  # Validations
  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :status, presence: true, inclusion: { in: %w[pending completed cancelled] }
end