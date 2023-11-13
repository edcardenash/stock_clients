class UpdateClientProductsJob < ApplicationJob
  queue_as :default

  def perform
    last_processed_invoice_id = obtain_last_processed_invoice_id
    Invoice.includes(:products).where('id > ?', last_processed_invoice_id).find_each do |invoice|
      process_invoice(invoice)
    end
  end

  private

  def process_invoice(invoice)
    invoice.products.each do |product|
      ClientProduct.find_or_create_by(client: invoice.client, product: product) do |client_product|
        client_product.first_invoice_id ||= invoice.id
      end
    end
    update_last_processed_invoice_id(invoice.id)
  end

  def obtain_last_processed_invoice_id
    setting = AppSetting.find_by(key: 'last_processed_invoice_id')
    setting ? setting.value.to_i : 0
  end

  def update_last_processed_invoice_id(invoice_id)
    setting = AppSetting.find_or_create_by(key: 'last_processed_invoice_id')
    setting.update(value: invoice_id.to_s)
  end

end
