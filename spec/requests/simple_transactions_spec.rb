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
            status: 'active'
          }
        }
      end

      it "取引が作成されること" do
        expect {
          post simple_transactions_path, params: valid_params
        }.to change(SimpleTransaction, :count).by(1)
      end

      it "作成後にリダイレクトすること" do
        post simple_transactions_path, params: valid_params
        expect(response).to have_http_status(:redirect)
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
end
