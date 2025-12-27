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

      if params[:date_from].present?
        date_from = Date.parse(params[:date_from]).beginning_of_day
        @api_call_logs = @api_call_logs.where('called_at >= ?', date_from)
      end

      if params[:endpoint].present?
        @api_call_logs = @api_call_logs.where('endpoint LIKE ?', "%#{params[:endpoint]}%")
      end

      @api_call_logs = @api_call_logs.limit(100)
    end

    def show
      @api_call_log = ApiCallLog.find(params[:id])
    end
  end
end
