class UpdateClientProductsJob < ApplicationJob
  queue_as :default

  def perform
    last_processed_invoice_id = obtain_last_processed_invoice_id
    Client.find_each do |client|
      LaudusApiService.new.get_invoices_list_by_customer(client.customer_id, last_processed_invoice_id).each do |invoice|
        process_invoice(client, invoice)
      end
    end
  end

  private

  def process_invoice(client, invoice)
    invoice['items'].each do |item|
      product_id = item['product']['productId']
      product = Product.find_or_create_by(product_id: product_id)
      ClientProduct.find_or_create_by(client: client, product: product) do |client_product|
        client_product.first_invoice_id ||= invoice['salesInvoiceId']
      end
    end
    update_last_processed_invoice_id(invoice['salesInvoiceId'])

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
