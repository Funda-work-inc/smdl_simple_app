class CreateApiCallLogs < ActiveRecord::Migration[7.2]
  def change
    create_table :api_call_logs do |t|
      t.string :api_type, null: false
      t.string :endpoint, null: false
      t.text :request_body
      t.text :response_body
      t.string :status, null: false
      t.references :simple_transaction, null: true, foreign_key: true
      t.datetime :called_at, null: false

      t.timestamps
    end

    add_index :api_call_logs, :called_at
    add_index :api_call_logs, :api_type
  end
end
