class CreateClients < ActiveRecord::Migration[7.0]
  def change
    create_table :clients do |t|
      t.integer :customer_id
      t.string :name

      t.timestamps
    end
  end
end
