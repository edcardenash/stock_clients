require 'rest-client'
require 'json'

class LaudusApiService
  BASE_URL = "https://api.laudus.cl"

  def initialize
    @username = ENV['LAUDUS_USERNAME']
    @password = ENV['LAUDUS_PASSWORD']
    @company_vat_id = ENV['LAUDUS_COMPANY_VAT_ID']
    @token = get_token
  end

  def get_token
    response = RestClient.post "#{BASE_URL}/security/login", {
      userName: @username,
      password: @password,
      companyVATId: @company_vat_id
    }.to_json, { content_type: :json, accept: :json }

    JSON.parse(response.body)["token"]
  rescue RestClient::ExceptionWithResponse => e
    e.response
  end

  def get_clients(filters = {})
    body = {
      options: {
        offset: 0,
        limit: 0
      },
      fields: ["customerId", "legalName", "VATId"],
      filterBy: filters,
      orderBy: [{ field: "legalName", direction: "ASC" }]
    }.to_json

    response = RestClient.post "#{BASE_URL}/sales/customers/list", body, headers
    puts response.body
    JSON.parse(response.body)
  rescue RestClient::ExceptionWithResponse => e
    puts e.response
    []
  end

  def get_client_details(customer_id)
    cached_client = $redis.get("client_#{customer_id}")
    return JSON.parse(cached_client) if cached_client

    response = RestClient.get "#{BASE_URL}/sales/customers/#{customer_id}", headers
    client_details = JSON.parse(response.body)
    $redis.set("client_#{customer_id}", client_details.to_json)
    $redis.expire("client_#{customer_id}", 12.hours.to_i)

    client_details
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "Error al obtener detalles del cliente: #{e.response}"
    nil
  end

  def get_client_purchase_record(customer_id)
    response = RestClient.get "#{BASE_URL}/reports/sales/invoices/byCustomer?customerId=#{customer_id}", headers
    JSON.parse(response.body)
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "Error al obtener historial de compras: #{e.response}"
    []
  end

  def get_product(product_id)
    cached_product = $redis.get("product_#{product_id}")
    return JSON.parse(cached_product) if cached_product

    response = RestClient.get "#{BASE_URL}/production/products/#{product_id}", headers
    product_details = JSON.parse(response.body)
    $redis.set("product_#{product_id}", product_details.to_json)
    $redis.expire("product_#{product_id}", 12.hours.to_i)

    product_details
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "Error al obtener detalles del producto: #{e.response}"
    nil
  end

  def get_stock_product(product_id)
    response = RestClient.get "#{BASE_URL}/production/products/#{product_id}/stock", headers
    JSON.parse(response.body)
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "Error al obtener stock del producto: #{e.response}"
    nil
  end

  def get_invoices_list_by_customer(customer_id, last_processed_invoice_id)
    body = {
      filterBy: [{ field: "customerId", operator: "=", value: customer_id },
                 { field: "salesInvoiceId", operator: ">", value: last_processed_invoice_id }],
      fields: ["salesInvoiceId", "customerId", "items"],
      options: { offset: 0, limit: 0 }
    }.to_json

    response = RestClient.post "#{BASE_URL}/sales/invoices/list", body, headers
    JSON.parse(response.body)
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "Error al obtener listado de facturas: #{e.response}"
    []
  end

  def get_invoice_details(salesInvoiceId)
    cached_invoice = $redis.get("invoice_#{salesInvoiceId}")
    return JSON.parse(cached_invoice) if cached_invoice

    response = RestClient.get "#{BASE_URL}/sales/invoices/#{salesInvoiceId}", headers
    invoice_details = JSON.parse(response.body)
    $redis.set("invoice_#{salesInvoiceId}", invoice_details.to_json)
    $redis.expire("invoice_#{salesInvoiceId}", 12.hours.to_i)

    invoice_details
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "Error al obtener detalles de la factura: #{e.response}"
    nil
  end

  private

  def headers
    { 'Authorization' => "Bearer #{@token}",
     'Content-Type' => 'application/json',
     'Accept' => 'application/json'
   }
  end
end
