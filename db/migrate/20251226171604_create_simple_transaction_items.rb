class CreateSimpleTransactionItems < ActiveRecord::Migration[7.2]
  def change
    create_table :simple_transaction_items do |t|
      t.references :simple_transaction, null: false, foreign_key: true
      t.string :item_name, null: false, limit: 255
      t.integer :item_count, null: false
      t.integer :item_price, null: false

      t.timestamps
    end
  end
end
