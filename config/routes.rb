Rails.application.routes.draw do
  root "home#index"
  devise_for :users

  # МОЙ профиль
  get "/me", to: "profiles#me", as: :my_profile
  get "/me/edit", to: "profiles#edit", as: :edit_my_profile
  patch "/me", to: "profiles#update"

  # ЧУЖИЕ профили
  resources :profiles, 
    only: [:index, :show], 
    constraints: { id: /[0-9]+/ }

  # Пользователи (если нужен список)
  resources :users, only: [:index, :show]

  # Игры с рецензиями (ФИЧА #3)
  resources :games do
    resources :reviews, shallow: true, only: [:create, :new, :index] do
      resources :comments, only: [:create, :destroy]
      resources :likes, only: [:create, :destroy]
    end
    post 'rate', on: :member, to: 'ratings#create'
  end
  
  # Отдельные маршруты для рецензий
  resources :reviews, only: [:show, :edit, :update, :destroy] do
    resources :comments, only: [:index, :create]
  end

  # Мои рецензии
  get 'my_reviews', to: 'reviews#my_reviews', as: :my_reviews
end