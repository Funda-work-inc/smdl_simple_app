class ApiCallLog < ApplicationRecord
  belongs_to :simple_transaction, optional: true

  validates :api_type, presence: true, inclusion: { in: %w[smdl sapi] }
  validates :endpoint, presence: true
  validates :status, presence: true, inclusion: { in: %w[success error] }
  validates :called_at, presence: true

  scope :smdl_logs, -> { where(api_type: 'smdl') }
  scope :sapi_logs, -> { where(api_type: 'sapi') }
  scope :success_logs, -> { where(status: 'success') }
  scope :error_logs, -> { where(status: 'error') }
  scope :recent, -> { order(called_at: :desc) }
end
