class SimpleTransaction < ApplicationRecord
  has_many :simple_transaction_items, dependent: :destroy
  has_many :api_call_logs, dependent: :destroy
  accepts_nested_attributes_for :simple_transaction_items, allow_destroy: true, reject_if: :all_blank

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :registration_datetime, presence: true
  validates :status, presence: true, inclusion: { in: %w[active cancelled deleted] }

  # Railsウェイ: ファットモデル - ビジネスロジックをモデルに集約

  # 取引と商品を一緒に作成するクラスメソッド
  def self.create_with_items(amount:, items:)
    transaction do
      simple_transaction = new(
        amount: amount,
        registration_datetime: Time.current,
        status: 'active'
      )

      items.each do |item|
        simple_transaction.simple_transaction_items.build(
          item_name: item[:item_name],
          item_count: item[:item_count],
          item_price: item[:item_price]
        )
      end

      simple_transaction.save!
      simple_transaction
    end
  end

  # 取引と商品を一緒に更新するインスタンスメソッド
  def update_with_items(amount:, items:)
    self.class.transaction do
      self.amount = amount
      simple_transaction_items.destroy_all

      items.each do |item|
        simple_transaction_items.build(
          item_name: item[:item_name],
          item_count: item[:item_count],
          item_price: item[:item_price]
        )
      end

      save!
    end
  end

  # ステータス変更メソッド
  def soft_delete!
    update!(status: 'deleted')
  end

  def cancel!
    update!(status: 'cancelled')
  end
end
