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

    def edit
      @simple_transaction = SimpleTransaction.includes(:simple_transaction_items).find(params[:id])
    end

    def update
      @simple_transaction = SimpleTransaction.find(params[:id])

      if @simple_transaction.update(simple_transaction_params)
        redirect_to admin_simple_transaction_path(@simple_transaction), notice: '取引を更新しました'
      else
        render :edit, status: :unprocessable_entity
      end
    end

    def destroy
      @simple_transaction = SimpleTransaction.find(params[:id])
      @simple_transaction.update!(status: 'deleted')
      redirect_to admin_simple_transactions_path, notice: '取引を削除しました'
    end

    def cancel
      @simple_transaction = SimpleTransaction.find(params[:id])
      @simple_transaction.update!(status: 'cancelled')
      redirect_to admin_simple_transaction_path(@simple_transaction), notice: '取引をキャンセルしました'
    end

    private

    def simple_transaction_params
      params.require(:simple_transaction).permit(
        :amount,
        simple_transaction_items_attributes: [:id, :item_name, :item_count, :item_price, :_destroy]
      )
    end
  end
end
