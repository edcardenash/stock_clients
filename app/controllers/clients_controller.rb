class ClientsController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :index ]
  def index
    api_service = LaudusApiService.new
    filters = [{
      field: "customerId",
      operator: ">=",
      value: 0
    }]
    @clients = api_service.get_clients(filters)
  end
end
