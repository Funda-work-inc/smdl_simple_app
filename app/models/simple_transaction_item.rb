class SimpleTransactionItem < ApplicationRecord
  belongs_to :simple_transaction

  validates :item_name, presence: true, length: { maximum: 255 }
  validates :item_count, presence: true, numericality: { only_integer: true, greater_than: 0, less_than_or_equal_to: 99999 }
  validates :item_price, presence: true, numericality: { only_integer: true, greater_than: 0 }
end
