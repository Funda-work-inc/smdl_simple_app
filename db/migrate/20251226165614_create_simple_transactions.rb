class CreateSimpleTransactions < ActiveRecord::Migration[7.2]
  def change
    create_table :simple_transactions do |t|
      t.integer :amount, null: false
      t.datetime :registration_datetime, null: false
      t.string :status, null: false, default: 'active'

      t.timestamps
    end

    add_index :simple_transactions, :status
    add_index :simple_transactions, :registration_datetime
  end
end
