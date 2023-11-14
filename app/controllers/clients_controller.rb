class ClientsController < ApplicationController
  skip_before_action :authenticate_user!, only: [:index, :show]
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
    api_service = LaudusApiService.new
    @client = api_service.get_client_details(params[:id])
    customer_id = params[:id].to_i

    product_page = params[:product_page] || 1
    per_page = 10

    @purchases = api_service.get_paginated_purchases(customer_id, product_page, per_page)
  end

end
