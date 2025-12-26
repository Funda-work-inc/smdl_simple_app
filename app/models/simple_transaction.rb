class SimpleTransaction < ApplicationRecord
  has_many :simple_transaction_items, dependent: :destroy
  has_many :api_call_logs, dependent: :destroy
  accepts_nested_attributes_for :simple_transaction_items, allow_destroy: true, reject_if: :all_blank

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :registration_datetime, presence: true
  validates :status, presence: true, inclusion: { in: %w[active cancelled deleted] }
end
