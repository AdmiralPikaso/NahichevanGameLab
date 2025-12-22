Rails.application.routes.draw do
  root "home#index"
  devise_for :users

  # МОЙ профиль
  get "/me", to: "profiles#me", as: :my_profile
  get "/me/edit", to: "profiles#edit", as: :edit_my_profile
  patch "/me", to: "profiles#update"

  # ЧУЖИЕ профили + список, но ID только цифры
  # ЧУЖИЕ профили
  resources :profiles, 
    only: [:index, :show], 
    constraints: { id: /[0-9]+/ }

  resources :games do
    # Маршруты для добавления игр в коллекции прямо со страницы игры
    member do
      post 'add_to_collection', to: 'games#add_to_collection'
      delete 'remove_from_collection/:collection_id', to: 'games#remove_from_collection', as: 'remove_from_collection'
    end
    
    # Коллекции для конкретной игры
    resources :collection_games, only: [:index], module: :games
  end
  
  resources :developers, only: [:index, :show]
  
  # ФИЧА #4: Коллекции, вишлист, друзья
  resources :collections do
    member do
      post 'add_game/:game_id', to: 'collections#add_game', as: 'add_game'
      delete 'remove_game/:game_id', to: 'collections#remove_game', as: 'remove_game'
      post 'add_multiple_games', to: 'collections#add_multiple_games'
      get 'stats', to: 'collections#stats'
    end
    
    collection do
      get 'my', to: 'collections#my' # Мои коллекции (альтернатива index)
      get 'search', to: 'collections#search' # Поиск по коллекциям
      get 'public', to: 'collections#public' # Публичные коллекции
      post 'quick_create', to: 'collections#quick_create' # Быстрое создание
    end
    
    # Игры в коллекции
    resources :games, only: [:index], controller: 'collection_games'
  end
  
  # Отдельные маршруты для управления играми в коллекциях
  resources :collection_games, only: [:create, :destroy]
  
  # Вишлист (список желаний)
  resources :wishlists, only: [:index, :create, :destroy] do
    collection do
      get 'my', to: 'wishlists#my'
    end
  end
  
  
  # Друзья
  resources :friendships, only: [:index, :create, :update, :destroy] do
    collection do
      get 'pending', to: 'friendships#pending'
      get 'suggestions', to: 'friendships#suggestions' # Предложения друзей
    end
    
    member do
      patch 'accept', to: 'friendships#accept', as: 'accept'
      patch 'reject', to: 'friendships#reject', as: 'reject'
    end
  end
  
  # Пользователи
  resources :users, only: [:index, :show], constraints: { id: /[0-9]+/ } do
    member do
      get 'collections', to: 'users#collections' # Коллекции пользователя
      get 'games', to: 'users#games' # Игры пользователя
      get 'friends', to: 'users#friends' # Друзья пользователя
      get 'stats', to: 'users#stats' # Статистика пользователя
    end
    
    collection do
      get 'search', to: 'users#search' # Поиск пользователей
      get 'with_collections', to: 'users#with_collections' # Пользователи с коллекциями
    end
  end
  
  # Быстрые действия
  namespace :quick do
    post 'add_to_collection', to: 'actions#add_to_collection'
    post 'add_to_wishlist', to: 'actions#add_to_wishlist'
    post 'send_friend_request', to: 'actions#send_friend_request'
  end
  
  # Статистика и аналитика
  namespace :analytics do
    get 'collections', to: 'dashboard#collections'
    get 'games', to: 'dashboard#games'
    get 'friends', to: 'dashboard#friends'
    get 'user/:id', to: 'dashboard#user', as: :user
  end
  
  # API маршруты (если нужно)
  namespace :api do
    namespace :v1 do
      resources :collections, only: [:index, :show, :create]
      resources :collection_games, only: [:create, :destroy]
      resources :games, only: [:index]
    end
  end
  
  # Обработка ошибок
  match '/404', to: 'errors#not_found', via: :all
  match '/500', to: 'errors#internal_server_error', via: :all
  
  # Health check
  get '/health', to: 'health#index'

  resources :wishlists, only: [:index, :create, :destroy] do
  collection do
    post 'quick_add', to: 'wishlists#quick_add'
  end
  end
  resources :games do
  member do
    # Вишлист
    post 'add_to_wishlist', to: 'games#add_to_wishlist'
    delete 'remove_from_wishlist', to: 'games#remove_from_wishlist'
    post 'toggle_wishlist', to: 'games#toggle_wishlist'
    
    # Коллекции
    post 'add_to_collection', to: 'games#add_to_collection'
  end
  
  collection do
    get 'wishlisted', to: 'games#wishlisted_games'
    get 'search', to: 'games#search'
  end
  end

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