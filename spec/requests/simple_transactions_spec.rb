require 'rails_helper'

RSpec.describe "SimpleTransactions", type: :request do
  describe "GET /simple_transactions/new" do
    it "取引登録画面が正常に表示されること" do
      get new_simple_transaction_path
      expect(response).to have_http_status(:success)
    end
  end

  describe "POST /simple_transactions" do
    context "有効なパラメータの場合" do
      let(:valid_params) do
        {
          simple_transaction: {
            amount: 10000,
            registration_datetime: Time.current,
            status: 'active',
            simple_transaction_items_attributes: [
              { item_name: 'テスト商品', item_count: 1, item_price: 10000 }
            ]
          }
        }
      end

      it "取引が作成されること" do
        expect {
          post simple_transactions_path, params: valid_params
        }.to change(SimpleTransaction, :count).by(1)
      end

      it "作成後に結果表示画面にリダイレクトすること" do
        post simple_transactions_path, params: valid_params
        transaction = SimpleTransaction.last
        expect(response).to redirect_to(simple_transaction_path(transaction))
      end
    end

    context "無効なパラメータの場合" do
      let(:invalid_params) do
        {
          simple_transaction: {
            amount: nil,
            registration_datetime: nil,
            status: nil
          }
        }
      end

      it "取引が作成されないこと" do
        expect {
          post simple_transactions_path, params: invalid_params
        }.not_to change(SimpleTransaction, :count)
      end

      it "newテンプレートを再表示すること" do
        post simple_transactions_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "GET /simple_transactions/:id" do
    let(:transaction) { create(:simple_transaction) }
    let!(:item1) { create(:simple_transaction_item, simple_transaction: transaction, item_name: '商品1', item_count: 2, item_price: 5000) }
    let!(:item2) { create(:simple_transaction_item, simple_transaction: transaction, item_name: '商品2', item_count: 1, item_price: 3000) }

    it "取引結果表示画面が正常に表示されること" do
      get simple_transaction_path(transaction)
      expect(response).to have_http_status(:success)
    end

    it "取引情報が表示されること" do
      get simple_transaction_path(transaction)
      expect(response.body).to include(transaction.id.to_s)
      expect(response.body).to include('¥10,000')
    end

    it "商品情報が表示されること" do
      get simple_transaction_path(transaction)
      expect(response.body).to include('商品1')
      expect(response.body).to include('商品2')
    end
  end
end
