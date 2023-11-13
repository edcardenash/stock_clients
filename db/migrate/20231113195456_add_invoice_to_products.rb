class AddInvoiceToProducts < ActiveRecord::Migration[7.0]
  def change
    add_column :products, :first_invoice_id, :integer
  end
end
