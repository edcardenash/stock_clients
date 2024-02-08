Rails.application.routes.draw do
  devise_for :users
  root to: "pages#home"
  resources :clients
  post 'clients/:client_id/update_steel', to: 'clients#update_steel', as: 'update_steel_for_client'

end
