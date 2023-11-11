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
        limit: 50
      },
      fields: ["customerId", "legalName", "VATId"],
      filterBy: filters,
      orderBy: [{ field: "VATId", direction: "ASC" }]
    }.to_json

    response = RestClient.post "#{BASE_URL}/sales/customers/list", body, headers
    JSON.parse(response.body)
  rescue RestClient::ExceptionWithResponse => e
    e.response
  end

  private

  def headers
    { 'Authorization' => "Bearer #{@token}", 'Content-Type' => 'application/json' }
  end
end
