class UpdateClientProductsJob < ApplicationJob
  queue_as :default

  def perform

    last_processed_invoice_id = obtain_last_processed_invoice_id
    Invoice.where('id > ?', last_processed_invoice_id).find_each do |invoice|
      process_invoice(invoice)
    end
  end

  private

  def process_invoice(invoice)
    invoice.products.each do |product|
      ClientProduct.find_or_create_by(client_id: invoice.client_id, product_id: product.id) do |cp|
        cp.first_invoice_id = invoice.id
      end
    end
    update_last_processed_invoice_id(invoice.id)
  end

  def obtain_last_processed_invoice_id

  end

  def update_last_processed_invoice_id(invoice_id)

  end
end
