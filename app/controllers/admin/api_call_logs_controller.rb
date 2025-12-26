module Admin
  class ApiCallLogsController < ApplicationController
    def index
      @api_call_logs = ApiCallLog.includes(:simple_transaction).recent

      if params[:api_type].present?
        @api_call_logs = @api_call_logs.where(api_type: params[:api_type])
      end

      if params[:status].present?
        @api_call_logs = @api_call_logs.where(status: params[:status])
      end

      @api_call_logs = @api_call_logs.limit(100)
    end

    def show
      @api_call_log = ApiCallLog.find(params[:id])
    end
  end
end
