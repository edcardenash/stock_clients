class ClientesController < ApplicationController
  def index
    api_service = LaudusApiService.new
    @clients = api_service.get_clients
  end
end
