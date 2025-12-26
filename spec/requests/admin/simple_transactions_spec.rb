require 'rails_helper'

RSpec.describe "Admin::SimpleTransactions", type: :request do
  let!(:transaction1) do
    create(:simple_transaction, amount: 10000, registration_datetime: Time.zone.parse('2025-12-25 10:00:00'))
  end
  let!(:transaction2) do
    create(:simple_transaction, amount: 20000, registration_datetime: Time.zone.parse('2025-12-26 15:00:00'))
  end
  let!(:item1) { create(:simple_transaction_item, simple_transaction: transaction1) }
  let!(:item2) { create(:simple_transaction_item, simple_transaction: transaction2) }

  describe "GET /admin/simple_transactions" do
    it "管理者画面の取引一覧が正常に表示されること" do
      get admin_simple_transactions_path
      expect(response).to have_http_status(:success)
    end

    it "全ての取引が表示されること" do
      get admin_simple_transactions_path
      expect(response.body).to include(transaction1.id.to_s)
      expect(response.body).to include(transaction2.id.to_s)
    end

    context "取引IDで検索する場合" do
      it "指定した取引IDのみ表示されること" do
        get admin_simple_transactions_path, params: { id: transaction1.id }
        expect(response.body).to include('¥10,000')
        expect(response.body).not_to include('¥20,000')
      end
    end

    context "登録日（開始）で検索する場合" do
      it "指定日以降の取引のみ表示されること" do
        get admin_simple_transactions_path, params: { date_from: '2025-12-26' }
        expect(response.body).not_to include('2025/12/25')
        expect(response.body).to include('2025/12/26')
      end
    end

    context "登録日（終了）で検索する場合" do
      it "指定日以前の取引のみ表示されること" do
        get admin_simple_transactions_path, params: { date_to: '2025-12-25' }
        expect(response.body).to include('2025/12/25')
        expect(response.body).not_to include('2025/12/26')
      end
    end
  end

  describe "GET /admin/simple_transactions/:id" do
    it "管理者画面の取引詳細が正常に表示されること" do
      get admin_simple_transaction_path(transaction1)
      expect(response).to have_http_status(:success)
    end

    it "取引情報が表示されること" do
      get admin_simple_transaction_path(transaction1)
      expect(response.body).to include(transaction1.id.to_s)
      expect(response.body).to include('¥10,000')
    end

    it "商品情報が表示されること" do
      get admin_simple_transaction_path(transaction1)
      expect(response.body).to include(item1.item_name)
    end
  end
end
