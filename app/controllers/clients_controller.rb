class ClientsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index ]
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

  # private

  # def number?(string)
  #   true if Integer(string) rescue false
  # end
end
