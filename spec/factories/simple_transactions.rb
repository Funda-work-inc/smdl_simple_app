FactoryBot.define do
  factory :simple_transaction do
    amount { 10000 }
    registration_datetime { Time.current }
    status { 'active' }
  end
end
