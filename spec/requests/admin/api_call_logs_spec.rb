require 'rails_helper'

RSpec.describe "Admin::ApiCallLogs", type: :request do
  let!(:transaction1) do
    create(:simple_transaction, amount: 10000, registration_datetime: Time.zone.parse('2025-12-25 10:00:00'))
  end
  let!(:transaction2) do
    create(:simple_transaction, amount: 20000, registration_datetime: Time.zone.parse('2025-12-26 15:00:00'))
  end

  let!(:log1) do
    create(:api_call_log,
           api_type: 'sapi',
           endpoint: 'POST /api/v1/simple_transactions',
           status: 'success',
           simple_transaction: transaction1,
           called_at: Time.zone.parse('2025-12-25 10:00:00'))
  end
  let!(:log2) do
    create(:api_call_log,
           api_type: 'sapi',
           endpoint: 'PUT /api/v1/simple_transactions/2',
           status: 'success',
           simple_transaction: transaction2,
           called_at: Time.zone.parse('2025-12-26 15:00:00'))
  end
  let!(:log3) do
    create(:api_call_log,
           api_type: 'sapi',
           endpoint: 'POST /api/v1/simple_transactions',
           status: 'error',
           simple_transaction: nil,
           called_at: Time.zone.parse('2025-12-26 16:00:00'))
  end

  describe "GET /admin/api_call_logs" do
    it "管理者画面のAPI呼び出し履歴一覧が正常に表示されること" do
      get admin_api_call_logs_path
      expect(response).to have_http_status(:success)
    end

    it "全てのログが表示されること" do
      get admin_api_call_logs_path
      expect(response.body).to include('POST /api/v1/simple_transactions')
      expect(response.body).to include('PUT /api/v1/simple_transactions/2')
    end

    context "日付で検索する場合" do
      it "指定日のログのみ表示されること" do
        get admin_api_call_logs_path, params: { date_from: '2025-12-26' }
        expect(response.body).not_to include('2025-12-25')
        expect(response.body).to include('2025-12-26')
      end
    end

    context "エンドポイントで検索する場合" do
      it "指定したエンドポイントのログのみ表示されること" do
        get admin_api_call_logs_path, params: { endpoint: 'PUT' }
        expect(response.body).to include('PUT /api/v1/simple_transactions/2')
        expect(response.body).not_to include('2025/12/25')
      end
    end

    context "ステータスで検索する場合" do
      it "指定したステータスのログのみ表示されること" do
        get admin_api_call_logs_path, params: { status: 'error' }
        expect(response.body).to include('error')
        expect(response.body).to include('2025-12-26 16:00:00')
      end
    end

    it "最新のログから順に表示されること" do
      get admin_api_call_logs_path
      body = response.body
      log3_position = body.index('2025-12-26 16:00:00')
      log2_position = body.index('2025-12-26 15:00:00')
      log1_position = body.index('2025-12-25 10:00:00')

      expect(log3_position).to be < log2_position
      expect(log2_position).to be < log1_position
    end
  end
end
