class Product < ApplicationRecord
  has_many :client_products
  has_many :clients, through: :client_products
  has_many :invoice_products
  has_many :invoices, through: :invoice_products
end
