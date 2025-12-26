module Api
  module V1
    class SimpleTransactionsController < ApplicationController
      skip_before_action :verify_authenticity_token

      def create
        @simple_transaction = SimpleTransaction.new(
          amount: transaction_params[:amount],
          registration_datetime: Time.current,
          status: 'active'
        )

        items = transaction_params[:items] || []
        items.each do |item|
          @simple_transaction.simple_transaction_items.build(
            item_name: item[:item_name],
            item_count: item[:item_count],
            item_price: item[:item_price]
          )
        end

        if @simple_transaction.save
          log_api_call('sapi', 'POST /api/v1/simple_transactions', 'success')
          render json: {
            id: @simple_transaction.id,
            amount: @simple_transaction.amount,
            status: @simple_transaction.status,
            message: 'Transaction created successfully'
          }, status: :created
        else
          log_api_call('sapi', 'POST /api/v1/simple_transactions', 'error')
          render json: {
            errors: @simple_transaction.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      def update
        @simple_transaction = SimpleTransaction.find(params[:id])

        @simple_transaction.amount = transaction_params[:amount]
        @simple_transaction.simple_transaction_items.destroy_all

        items = transaction_params[:items] || []
        items.each do |item|
          @simple_transaction.simple_transaction_items.build(
            item_name: item[:item_name],
            item_count: item[:item_count],
            item_price: item[:item_price]
          )
        end

        if @simple_transaction.save
          log_api_call('sapi', "PUT /api/v1/simple_transactions/#{params[:id]}", 'success')
          render json: {
            id: @simple_transaction.id,
            amount: @simple_transaction.amount,
            status: @simple_transaction.status,
            message: 'Transaction updated successfully'
          }, status: :ok
        else
          log_api_call('sapi', "PUT /api/v1/simple_transactions/#{params[:id]}", 'error')
          render json: {
            errors: @simple_transaction.errors.full_messages
          }, status: :unprocessable_entity
        end
      end

      private

      def transaction_params
        params.permit(:amount, items: [:item_name, :item_count, :item_price])
      end

      def log_api_call(api_type, endpoint, status)
        ApiCallLog.create(
          api_type: api_type,
          endpoint: endpoint,
          request_body: request.body.read,
          response_body: response.body,
          status: status,
          simple_transaction_id: @simple_transaction&.id,
          called_at: Time.current
        )
      rescue => e
        Rails.logger.error "Failed to log API call: #{e.message}"
      end
    end
  end
end
