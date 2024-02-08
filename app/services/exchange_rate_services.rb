require 'net/http'
require 'json'

module ExchangeRateServices
  def self.convert_cny_to_usd(amount_in_cny, api_key)
    url = URI("https://v6.exchangerate-api.com/v6/#{api_key}/latest/CNY")
    response = Net::HTTP.get(url)
    data = JSON.parse(response)
    exchange_rate = data['conversion_rates']['USD']
    amount_in_cny * exchange_rate
  rescue StandardError => e
    Rails.logger.error "Error al convertir CNY a USD: #{e.message}"
    nil
  end
end
