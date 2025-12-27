module Api
  module V1
    class SimpleTransactionsController < ApplicationController
      skip_before_action :verify_authenticity_token

      def create
        # Railsウェイ: ビジネスロジックはモデルに委譲
        @simple_transaction = SimpleTransaction.create_with_items(
          amount: transaction_params[:amount],
          items: transaction_params[:items] || []
        )

        log_api_call('sapi', 'POST /api/v1/simple_transactions', 'success')
        render json: {
          id: @simple_transaction.id,
          amount: @simple_transaction.amount,
          status: @simple_transaction.status,
          message: 'Transaction created successfully'
        }, status: :created
      rescue ActiveRecord::RecordInvalid => e
        log_api_call('sapi', 'POST /api/v1/simple_transactions', 'error')
        render json: {
          errors: e.record.errors.full_messages
        }, status: :unprocessable_entity
      end

      def update
        @simple_transaction = SimpleTransaction.find(params[:id])

        # Railsウェイ: ビジネスロジックはモデルに委譲
        @simple_transaction.update_with_items(
          amount: transaction_params[:amount],
          items: transaction_params[:items] || []
        )

        log_api_call('sapi', "PUT /api/v1/simple_transactions/#{params[:id]}", 'success')
        render json: {
          id: @simple_transaction.id,
          amount: @simple_transaction.amount,
          status: @simple_transaction.status,
          message: 'Transaction updated successfully'
        }, status: :ok
      rescue ActiveRecord::RecordInvalid => e
        log_api_call('sapi', "PUT /api/v1/simple_transactions/#{params[:id]}", 'error')
        render json: {
          errors: e.record.errors.full_messages
        }, status: :unprocessable_entity
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
