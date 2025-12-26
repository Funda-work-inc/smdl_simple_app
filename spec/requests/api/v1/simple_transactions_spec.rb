require 'rails_helper'

RSpec.describe "Api::V1::SimpleTransactions", type: :request do
  describe "POST /api/v1/simple_transactions" do
    let(:valid_params) do
      {
        amount: 10000,
        items: [
          { item_name: 'テスト商品1', item_count: 2, item_price: 3000 },
          { item_name: 'テスト商品2', item_count: 1, item_price: 4000 }
        ]
      }
    end

    let(:invalid_params) do
      {
        amount: nil,
        items: []
      }
    end

    context "正常な取引登録" do
      it "ステータスコード201が返ること" do
        post "/api/v1/simple_transactions", params: valid_params, as: :json
        expect(response).to have_http_status(:created)
      end

      it "取引が作成されること" do
        expect {
          post "/api/v1/simple_transactions", params: valid_params, as: :json
        }.to change(SimpleTransaction, :count).by(1)
      end

      it "商品が作成されること" do
        expect {
          post "/api/v1/simple_transactions", params: valid_params, as: :json
        }.to change(SimpleTransactionItem, :count).by(2)
      end

      it "正しいJSONレスポンスが返ること" do
        post "/api/v1/simple_transactions", params: valid_params, as: :json
        json = JSON.parse(response.body)

        expect(json['id']).to be_present
        expect(json['amount']).to eq(10000)
        expect(json['status']).to eq('active')
        expect(json['message']).to eq('Transaction created successfully')
      end

      it "API呼び出しログが記録されること" do
        expect {
          post "/api/v1/simple_transactions", params: valid_params, as: :json
        }.to change(ApiCallLog, :count).by(1)

        log = ApiCallLog.last
        expect(log.api_type).to eq('sapi')
        expect(log.endpoint).to eq('POST /api/v1/simple_transactions')
        expect(log.status).to eq('success')
      end
    end

    context "バリデーションエラー" do
      it "ステータスコード422が返ること" do
        post "/api/v1/simple_transactions", params: invalid_params, as: :json
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "エラーメッセージが返ること" do
        post "/api/v1/simple_transactions", params: invalid_params, as: :json
        json = JSON.parse(response.body)

        expect(json['errors']).to be_present
        expect(json['errors']).to be_an(Array)
      end

      it "API呼び出しログ(エラー)が記録されること" do
        expect {
          post "/api/v1/simple_transactions", params: invalid_params, as: :json
        }.to change(ApiCallLog, :count).by(1)

        log = ApiCallLog.last
        expect(log.status).to eq('error')
      end
    end
  end

  describe "PUT /api/v1/simple_transactions/:id" do
    let!(:transaction) { create(:simple_transaction, amount: 10000) }
    let!(:item) { create(:simple_transaction_item, simple_transaction: transaction) }

    let(:update_params) do
      {
        amount: 15000,
        items: [
          { item_name: '更新商品', item_count: 3, item_price: 5000 }
        ]
      }
    end

    context "正常な取引更新" do
      it "ステータスコード200が返ること" do
        put "/api/v1/simple_transactions/#{transaction.id}", params: update_params, as: :json
        expect(response).to have_http_status(:ok)
      end

      it "取引が更新されること" do
        put "/api/v1/simple_transactions/#{transaction.id}", params: update_params, as: :json
        transaction.reload
        expect(transaction.amount).to eq(15000)
      end

      it "商品が更新されること" do
        put "/api/v1/simple_transactions/#{transaction.id}", params: update_params, as: :json
        transaction.reload
        expect(transaction.simple_transaction_items.count).to eq(1)
        expect(transaction.simple_transaction_items.first.item_name).to eq('更新商品')
      end

      it "正しいJSONレスポンスが返ること" do
        put "/api/v1/simple_transactions/#{transaction.id}", params: update_params, as: :json
        json = JSON.parse(response.body)

        expect(json['id']).to eq(transaction.id)
        expect(json['amount']).to eq(15000)
        expect(json['message']).to eq('Transaction updated successfully')
      end

      it "API呼び出しログが記録されること" do
        expect {
          put "/api/v1/simple_transactions/#{transaction.id}", params: update_params, as: :json
        }.to change(ApiCallLog, :count).by(1)

        log = ApiCallLog.last
        expect(log.api_type).to eq('sapi')
        expect(log.endpoint).to eq("PUT /api/v1/simple_transactions/#{transaction.id}")
        expect(log.status).to eq('success')
      end
    end

    context "存在しない取引の更新" do
      it "ステータスコード404が返ること" do
        put "/api/v1/simple_transactions/99999", params: update_params, as: :json
        expect(response).to have_http_status(:not_found)
      end
    end
  end
end
