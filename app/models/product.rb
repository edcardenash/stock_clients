class Product < ApplicationRecord
  has_many :client_products
  has_many :clients, through: :client_products
end
