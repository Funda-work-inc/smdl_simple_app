FactoryBot.define do
  factory :simple_transaction_item do
    association :simple_transaction
    item_name { "テスト商品" }
    item_count { 1 }
    item_price { 1000 }
  end
end
