class SimpleTransactionsController < ApplicationController
  def new
    @simple_transaction = SimpleTransaction.new
    # デフォルトで1つの商品フォームを表示
    @simple_transaction.simple_transaction_items.build
  end

  def create
    @simple_transaction = SimpleTransaction.new(simple_transaction_params)

    if @simple_transaction.save
      redirect_to simple_transaction_path(@simple_transaction), notice: '取引を登録しました。'
    else
      render :new, status: :unprocessable_entity
    end
  end

  def show
    @simple_transaction = SimpleTransaction.find(params[:id])
  end

  private

  def simple_transaction_params
    params.require(:simple_transaction).permit(
      :amount,
      :registration_datetime,
      :status,
      simple_transaction_items_attributes: [:id, :item_name, :item_count, :item_price, :_destroy]
    )
  end
end
