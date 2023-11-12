class ClientsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
  def index
    api_service = LaudusApiService.new
    filters = []

    if params[:search].present?
      filters.push({ field: "legalName", operator: "contains", value: params[:search] })
      # if number?(params[:search])
      # filters.push({ field: "VATId", operator: "contains", value: params[:search] })
      # end
    else
      filters.push({ field: "customerId", operator: ">=", value: 0 })
    end
      clients = api_service.get_clients(filters)
      @clients = Kaminari.paginate_array(clients).page(params[:page]).per(10)
  end

  def show
    api_service = LaudusApiService.new
    @client = api_service.get_client_details(params[:id])
    customer_id = params[:id].to_i
    invoices_list = api_service.get_invoices_list_by_customer(customer_id)

    products_hash = {}
    invoices_list.each do |invoice|
      invoice_id = invoice['salesInvoiceId']
      invoice_details = api_service.get_invoice_details(invoice_id)
      next unless invoice_details && invoice_details['items']

      invoice_details['items'].each do |item|
        product_id = item['product']['productId']
        next if products_hash[product_id]

        product_details = api_service.get_product(product_id)
        stock_details = api_service.get_stock_product(product_id)
        products_hash[product_id] = { product: product_details, stock: stock_details['stock'] }
      end
    end
    @purchase_products = products_hash.values
  end


  # private

  # def number?(string)
  #   true if Integer(string) rescue false
  # end
end
