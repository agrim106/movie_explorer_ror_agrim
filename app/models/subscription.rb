class Subscription < ApplicationRecord
  belongs_to :user

  validates :start_date, presence: true
  validates :premium, inclusion: { in: [true, false] }
  validates :active, inclusion: { in: [true, false] }

  def active?
    self.active == true && (end_date.nil? || end_date > Time.current)
  end
end