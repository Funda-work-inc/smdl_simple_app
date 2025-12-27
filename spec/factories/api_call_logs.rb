FactoryBot.define do
  factory :api_call_log do
    api_type { 'sapi' }
    endpoint { 'POST /api/v1/simple_transactions' }
    request_body { '{"amount":10000,"items":[]}' }
    response_body { '{"id":1,"status":"success"}' }
    status { 'success' }
    simple_transaction { nil }
    called_at { Time.current }
  end
end
