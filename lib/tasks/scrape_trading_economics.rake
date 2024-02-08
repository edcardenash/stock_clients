namespace :scrape_trading_economics do
  desc "Scrape sunsirs for steel price to update STEEL variable"
  task update_steel: :environment do
    require 'nokogiri'
    require 'open-uri'
    require 'yaml'
    require 'exchange_rate_services'

    api_key = ENV['EXCHANGE_RATE_API_KEY']

    url = 'https://www.sunsirs.com/uk/sectors-13.html'
    doc = Nokogiri::HTML(URI.open(url))

    steel_price_element = doc.css('body > div > div > div.main > div.l-body > div:nth-child(3) > table > tbody > tr:nth-child(10) > td:nth-child(4)')
    steel_price_text = steel_price_element.text.strip
    steel_price_text = steel_price_text.gsub(',', '')
    steel_price = steel_price_text.to_f
    puts steel_price

    steel_price_per_kg = steel_price / 1000.0
    puts steel_price_per_kg

    steel_price_usd = ExchangeRateServices.convert_cny_to_usd(steel_price_per_kg, api_key)
    puts steel_price_usd

    config_path = Rails.root.join('config', 'steel.yml')
    config = YAML.safe_load(File.read(config_path), aliases: true)
    config['last_updated'] = Time.now.strftime("%Y-%m-%d %H:%M:%S")

    config['steel_value'] = steel_price_usd
    config['development']['steel_value'] = steel_price_usd
    config['default']['steel_value'] = steel_price_usd
    config['production']['steel_value'] = steel_price_usd

    File.open(config_path, 'w') { |f| f.write(config.to_yaml) }
    puts "Actualizado steel_value a #{config['steel_value']}"
  end
end
