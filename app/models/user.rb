class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  has_one :profile, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  
  after_create :create_profile

  # Отношения дружбы (будут работать после создания модели Friendship)
  has_many :friendships, dependent: :destroy
  has_many :inverse_friendships, class_name: "Friendship", foreign_key: "friend_id", dependent: :destroy
  
  # Упрощенные методы до создания полной модели Friendship
  
  # Все принятые друзья (в обе стороны)
  def accepted_friends
    if Friendship.table_exists?
      User.joins("INNER JOIN friendships ON (friendships.user_id = users.id OR friendships.friend_id = users.id)")
          .where("(friendships.user_id = ? OR friendships.friend_id = ?) AND friendships.status = 'accepted'", id, id)
          .where.not(id: id)
          .distinct
    else
      User.none  # Возвращаем пустой запрос если таблицы нет
    end
  end
  
  # Отправленные заявки (ожидающие)
  def pending_friends
    if Friendship.table_exists?
      User.joins(:inverse_friendships)
          .where(friendships: { user_id: id, status: 'pending' })
    else
      User.none
    end
  end
  
  # Полученные заявки (ожидающие)
  def requested_friends
    if Friendship.table_exists?
      User.joins(:friendships)
          .where(friendships: { friend_id: id, status: 'pending' })
    else
      User.none
    end
  end
  
  # Все друзья (алиас для удобства)
  def all_friends
    accepted_friends
  end
  
  # Проверка дружбы
  def friend_with?(user)
    return false unless Friendship.table_exists?
    
    Friendship.where(
      "(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)",
      id, user.id, user.id, id
    ).where(status: 'accepted').exists?
  end
  
  # Проверка отправленной заявки
  def pending_request_to?(user)
    return false unless Friendship.table_exists?
    
    friendships.where(friend_id: user.id, status: 'pending').exists?
  end
  
  # Проверка полученной заявки
  def pending_request_from?(user)
    return false unless Friendship.table_exists?
    
    inverse_friendships.where(user_id: user.id, status: 'pending').exists?
  end
  
  # Методы для удобства (работают без полной модели)
  
  # Получить статус дружбы с пользователем
  def friendship_status_with(other_user)
    return nil unless Friendship.table_exists?
    
    friendship = Friendship.find_by(user_id: id, friend_id: other_user.id) ||
                 Friendship.find_by(user_id: other_user.id, friend_id: id)
    
    return nil unless friendship
    
    if friendship.accepted?
      :friends
    elsif friendship.pending?
      friendship.user_id == id ? :request_sent : :request_received
    else
      nil
    end
  end
  
  # Можно ли добавить в друзья?
  def can_send_friend_request_to?(other_user)
    return false if id == other_user.id
    return false unless Friendship.table_exists?
    
    !friend_with?(other_user) && 
    !pending_request_to?(other_user) && 
    !pending_request_from?(other_user)
  end

  private
  
  def create_profile
    Profile.create(user: self) unless profile.present?
  end

  has_many :collections, dependent: :destroy
  
  after_create :create_default_collections
  
  private
  
  def create_default_collections
    Collection.create_default_collections_for_user(self)
  end

  def collections_statistics
  {
    total_collections: collections.count,
    total_games: collections.joins(:games).distinct.count(:game_id),
    average_games_per_collection: collections_count.zero? ? 0 : 
                                 (collections.joins(:games).distinct.count(:game_id).to_f / collections_count).round(1),
    most_common_genre: "Не определено" # Можно реализовать позже
  }
  end
  
  has_many :wishlists, dependent: :destroy
  has_many :wishlist_games, through: :wishlists, source: :game
  
  # Методы для вишлиста
  def in_wishlist?(game)
    wishlists.where(game_id: game.id).exists?
  end
  
  def wishlist_priority_for(game)
    wishlists.find_by(game_id: game.id)&.priority
  end

end