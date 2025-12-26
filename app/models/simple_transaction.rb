class SimpleTransaction < ApplicationRecord
  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :registration_datetime, presence: true
  validates :status, presence: true, inclusion: { in: %w[active cancelled deleted] }
end
