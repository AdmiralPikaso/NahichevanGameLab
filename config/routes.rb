Rails.application.routes.draw do
  # -------------------------
  # Главная
  # -------------------------
  root "home#index"

  # -------------------------
  # Devise (авторизация)
  # -------------------------
  devise_for :users

  # -------------------------
  # Мой профиль
  # -------------------------
  get "/me",       to: "profiles#me",   as: :my_profile
  get "/me/edit",  to: "profiles#edit", as: :edit_my_profile
  patch "/me",     to: "profiles#update"

  # -------------------------
  # Публичные профили
  # -------------------------
  resources :profiles, only: [:index, :show], constraints: { id: /\d+/ }

  # -------------------------
  # Игры
  # -------------------------
  resources :games do
    member do
      post   :add_to_collection
      delete :remove_from_wishlist
      post   :add_to_wishlist
      post   :toggle_wishlist
      post   :rate
    end

    collection do
      get :search
      get :wishlisted
    end

    resources :reviews, shallow: true, only: [:new, :create, :index, :show, :edit, :update, :destroy] do
      resources :comments, only: [:create, :destroy]
      resources :likes,    only: [:create, :destroy]
    end
  end

  # -------------------------
  # Разработчики
  # -------------------------
  resources :developers, only: [:index, :show]

  # -------------------------
  # Коллекции
  # -------------------------
  resources :collections do
    member do
      post   :add_game
      delete :remove_game
      post   :add_multiple_games
      get    :stats
    end

    collection do
      get  :my
      get  :search
      get  :public
      post :quick_create
    end

    resources :games, only: [:index], controller: "collection_games"
  end

  resources :collection_games, only: [:create, :destroy]

  # -------------------------
  # Вишлист (ИСПРАВЛЕНО: добавлен :show и :update)
  # -------------------------
  resources :wishlists, only: [:index, :show, :create, :update, :destroy] do
    collection do
      get  :my
      post :quick_add
    end
    
    member do
      # Для изменения приоритета
      patch :update_priority
    end
  end

  # -------------------------
  # Друзья
  # -------------------------
  resources :friendships, only: [:index, :create, :update, :destroy] do
    collection do
      get :pending
      get :suggestions
    end

    member do
      patch :accept
      patch :reject
    end
  end

  # -------------------------
  # Аналитика
  # -------------------------
  namespace :analytics do
    get :collections
    get :games
    get :friends
    get "user/:id", to: "dashboard#user", as: :user
  end

  # -------------------------
  # API
  # -------------------------
  namespace :api do
    namespace :v1 do
      resources :collections, only: [:index, :show, :create]
      resources :collection_games, only: [:create, :destroy]
      resources :games, only: [:index]
    end
  end

  # -------------------------
  # Ошибки
  # -------------------------
  match "/404", to: "errors#not_found", via: :all
  match "/500", to: "errors#internal_server_error", via: :all

  # -------------------------
  # Health check
  # -------------------------
  get "/health", to: "health#index"
end