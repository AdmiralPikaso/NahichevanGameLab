Rails.application.routes.draw do
  root "home#index"
  devise_for :users

  # МОЙ профиль (другой URL, без конфликта!)
  get "/me", to: "profiles#me", as: :my_profile
  get "/me/edit", to: "profiles#edit", as: :edit_my_profile
  patch "/me", to: "profiles#update"

  # ЧУЖИЕ профили + список
  resources :profiles, only: [:index, :show]
end




