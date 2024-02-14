class ClientsController < ApplicationController
  before_action :set_steel_value
  skip_before_action :authenticate_user!, only: [:index, :show, :update_steel]

  def index
    api_service = LaudusApiService.new
    filters = []
    if params[:search].present?
      filters.push({ field: "legalName", operator: "contains", value: params[:search] })
    else
      filters.push({ field: "customerId", operator: ">=", value: 0 })
    end
      clients = api_service.get_clients(filters)
      @clients = Kaminari.paginate_array(clients).page(params[:page]).per(10)
  end

  def show
    config_path = Rails.root.join('config', 'steel.yml')
    config = YAML.load_file(config_path)
    @steel_value = config['steel_value']
    @last_updated = config['last_updated']
    api_service = LaudusApiService.new
    @client = api_service.get_client_details(params[:id])
    @customer_id = params[:id].to_i

    all_stock = api_service.get_all_products_stock

    stock_hash = all_stock&.each_with_object({}) do |product, hash|
      hash[product['productId']] = product['stock']
    end || {}

    orders = api_service.get_orders_by_customer(@customer_id)

    products_hash = {}
    if orders
      orders.each do |order|
        product_id = order["items_product_productId"]
        next unless product_id && stock_hash.key?(product_id)

        products_hash[product_id] = {
          sku: order["items_product_sku"],
          description: order["items_product_description"],
          notes: convert_to_float(order["items_product_notes"]),
          stock: stock_hash[product_id].to_i,
          valor_usd: (convert_to_float(order["items_product_notes"]) * @steel_value).round(2)
        }
      end
    end
    product_page = params[:product_page] || 1
    per_page = 10
    total_products = products_hash.values.size
    @purchase_products = Kaminari.paginate_array(products_hash.values, total_count: total_products).page(product_page).per(per_page)

    flash.now[:error] = "No se pudo obtener el stock de los productos" if all_stock.nil?
  end

  def update_steel
    system 'rake scrape_trading_economics:update_steel'
    respond_to do |format|
      format.html { redirect_to client_path(params[:client_id]), notice: 'Steel value updated.' }
      format.js
    end
  end

  private

  def convert_to_float(value)
    value.to_s.gsub(',', '.').to_f
  end

  def set_steel_value
    config_path = Rails.root.join('config', 'steel.yml')
    config = YAML.load_file(config_path)
    @steel_value = config['steel_value']
  end
end
