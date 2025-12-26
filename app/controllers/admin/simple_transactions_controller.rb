module Admin
  class SimpleTransactionsController < ApplicationController
    def index
      @simple_transactions = SimpleTransaction.includes(:simple_transaction_items).order(created_at: :desc)

      # 検索機能
      if params[:id].present?
        @simple_transactions = @simple_transactions.where(id: params[:id])
      end

      if params[:date_from].present?
        date_from = Date.parse(params[:date_from]).beginning_of_day
        @simple_transactions = @simple_transactions.where('registration_datetime >= ?', date_from)
      end

      if params[:date_to].present?
        date_to = Date.parse(params[:date_to]).end_of_day
        @simple_transactions = @simple_transactions.where('registration_datetime <= ?', date_to)
      end
    end

    def show
      @simple_transaction = SimpleTransaction.includes(:simple_transaction_items).find(params[:id])
    end
  end
end
