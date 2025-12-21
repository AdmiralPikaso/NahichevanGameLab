Rails.application.routes.draw do
  root "home#index"
  devise_for :users

  # МОЙ профиль (безопасный URL)
  get "/me", to: "profiles#me", as: :my_profile
  get "/me/edit", to: "profiles#edit", as: :edit_my_profile
  patch "/me", to: "profiles#update"

  # ЧУЖИЕ профили + список, но ID только цифры
  # Это защищает от /profiles/me, /profiles/new и других конфликтов
  resources :profiles, 
    only: [:index, :show], 
    constraints: { id: /[0-9]+/ }

  resources :games
end




