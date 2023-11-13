class UpdateClientProductsJob < ApplicationJob
  queue_as :default

  def perform
    last_processed_invoice_id = obtain_last_processed_invoice_id
    LaudusApiService.new.get_recent_invoices(last_processed_invoice_id).each do |invoice|
      process_invoice(invoice)
    end
  end

  private

  def process_invoice(invoice)
    invoice['products'].each do |product_id|
      product = Product.find_or_create_by(product_id: product_id)
      client = Client.find_by(customer_id: invoice['customer_id'])

      ClientProduct.find_or_create_by(client: client, product: product) do |client_product|
        client_product.first_invoice_id ||= invoice['invoice_id']
      end
    end
    update_last_processed_invoice_id(invoice['invoice_id'])
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
