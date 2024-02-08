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
    $redis.expire("client_#{customer_id}", 730.hours.to_i)

    client_details
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "Error al obtener detalles del cliente: #{e.response}"
    nil
  end

  def get_product(product_id)
    cached_product = $redis.get("product_#{product_id}")
    return JSON.parse(cached_product) if cached_product

    response = RestClient.get "#{BASE_URL}/production/products/#{product_id}", headers
    product_details = JSON.parse(response.body)
    $redis.set("product_#{product_id}", product_details.to_json)
    $redis.expire("product_#{product_id}", 24.hours.to_i)

    product_details
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "Error al obtener detalles del producto: #{e.response}"
    nil
  end

  def get_all_products_stock
    cached_stock = $redis.get("all_products_stock")
    return JSON.parse(cached_stock) if cached_stock
    response = HTTParty.get(
      "#{BASE_URL}/production/products/stock",
      headers: {
        'Authorization' => "Bearer #{@token}",
        'Content-Type' => 'application/json',
        'Accept' => 'application/json'
      }
    )
    stock_data = JSON.parse(response.body)['products']
    $redis.set("all_products_stock", stock_data.to_json)
    $redis.expire("all_products_stock", 24 * 60 * 60)
    stock_data
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "Error al obtener stock de todos los productos: #{e.response}"
    nil
  rescue RuntimeError => e
    Rails.logger.error e.message
    nil
  end

  def get_orders_by_customer(customer_id)
    cached_orders = $redis.get("orders_#{customer_id}")

    if cached_orders
      Rails.logger.info "Retrieved orders for customer #{customer_id} from cache"
      return JSON.parse(cached_orders)
    end

    body = {
      fields: ["customer.customerId", "items.product.productId", "items.product.sku", "items.product.description", "items.product.notes"],
      filterBy: [{ field: "customer.customerId", operator: "=", value: customer_id }]
    }.to_json

    response = RestClient.post "#{BASE_URL}/sales/orders/list", body, headers
    orders = JSON.parse(response.body)

    $redis.set("orders_#{customer_id}", orders.to_json)

    Rails.logger.info "Retrieved orders for customer #{customer_id} from API and cached"

    orders
  rescue RestClient::ExceptionWithResponse => e
    Rails.logger.error "Error al obtener órdenes por cliente: #{e.response}"
    []
  end

  private

  def headers
    {
      'Authorization' => "Bearer #{@token}",
      'Content-Type' => 'application/json',
      'Accept' => 'application/json'
    }
  end
end
