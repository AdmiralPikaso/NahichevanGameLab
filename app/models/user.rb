class User < ApplicationRecord
  devise :database_authenticatable, :registerable,
         :recoverable, :rememberable, :validatable
  
  has_one :profile, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :ratings, dependent: :destroy
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  has_many :collections, dependent: :destroy
  has_many :wishlists, dependent: :destroy
  has_many :wishlist_games, through: :wishlists, source: :game
  
  after_create :create_profile
  after_create :create_default_collections

  # -------------------------
  # ОТНОШЕНИЯ ДЛЯ ДРУЗЕЙ
  # -------------------------
  
  # Отправленные заявки в друзья
  has_many :friendships, dependent: :destroy
  has_many :accepted_friendships, -> { where(status: 'accepted') }, 
           class_name: 'Friendship'
  has_many :accepted_friends, through: :accepted_friendships, source: :friend
  
  # Полученные заявки в друзья
  has_many :inverse_friendships, class_name: 'Friendship', 
           foreign_key: 'friend_id', dependent: :destroy
  has_many :inverse_accepted_friendships, -> { where(status: 'accepted') }, 
           class_name: 'Friendship', foreign_key: 'friend_id'
  has_many :inverse_accepted_friends, through: :inverse_accepted_friendships, 
           source: :user
  
  # Полный список друзей (с обеих сторон отношений)
  def friends
    User.where(id: accepted_friendships.pluck(:friend_id) + 
                  inverse_accepted_friendships.pluck(:user_id))
  end

  # Отправленные заявки (ожидающие)
  def pending_sent_requests
    friendships.where(status: 'pending')
  end

  # Полученные заявки (ожидающие)
  def pending_received_requests
    inverse_friendships.where(status: 'pending')
  end
  
  # ID всех друзей
  def friend_ids
    accepted_friendships.pluck(:friend_id) + inverse_accepted_friendships.pluck(:user_id)
  end
  
  # Все заявки в друзья (отправленные + полученные)
  def all_friendships
    Friendship.where(user_id: id).or(Friendship.where(friend_id: id))
  end
  
  # -------------------------
  # МЕТОДЫ ДЛЯ ПРОВЕРКИ СТАТУСА ДРУЖБЫ
  # -------------------------
  
  # Проверка, является ли пользователь другом
  def friends_with?(user)
    return false if id == user.id
    
    accepted_friendships.where(friend_id: user.id).exists? ||
    inverse_accepted_friendships.where(user_id: user.id).exists?
  end
  
  # Проверка отправленной заявки
  def pending_request_to?(user)
    friendships.where(status: 'pending').exists?(friend_id: user.id)
  end
  
  # Проверка полученной заявки
  def pending_request_from?(user)
    inverse_friendships.where(status: 'pending').exists?(user_id: user.id)
  end
  
  # Проверка, есть ли какое-либо отношение с пользователем
  def has_any_relationship_with?(user)
    return false if id == user.id
    
    Friendship.where(
      "(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)",
      id, user.id, user.id, id
    ).exists?
  end
  
  # Получить статус дружбы с пользователем
  def friendship_status_with(other_user)
    return nil if id == other_user.id
    
    friendship = Friendship.find_by(user_id: id, friend_id: other_user.id) ||
                 Friendship.find_by(user_id: other_user.id, friend_id: id)
    
    return nil unless friendship
    
    case friendship.status
    when 'accepted'
      :friends
    when 'pending'
      friendship.user_id == id ? :request_sent : :request_received
    when 'rejected'
      :rejected
    else
      nil
    end
  end
  
  # Получить объект дружбы с пользователем
  def friendship_with(other_user)
    Friendship.find_by(user_id: id, friend_id: other_user.id) ||
    Friendship.find_by(user_id: other_user.id, friend_id: id)
  end
  
  # Можно ли отправить заявку в друзья?
  def can_send_friend_request_to?(other_user)
    return false if id == other_user.id
    return false if friends_with?(other_user)
    return false if pending_request_to?(other_user)
    return false if pending_request_from?(other_user)
    
    # Проверяем, не отклонил ли уже этот пользователь заявку
    friendship = Friendship.find_by(user_id: id, friend_id: other_user.id, status: 'rejected')
    return false if friendship.present?
    
    true
  end
  
  # -------------------------
  # МЕТОДЫ ДЛЯ ЗАПРОСОВ
  # -------------------------
  
  # Все входящие заявки (для удобства)
  def incoming_requests
    pending_received_requests.includes(:user)
  end
  
  # Все исходящие заявки (для удобства)
  def outgoing_requests
    pending_sent_requests.includes(:friend)
  end
  
  # Количество новых (непросмотренных) заявок
  def new_friend_requests_count
    pending_received_requests.count
  end
  
  # -------------------------
  # МЕТОДЫ ДЛЯ ПОИСКА ДРУЗЕЙ
  # -------------------------
  
  # Предложения друзей (пользователи, с которыми еще нет отношений)
  def friend_suggestions(limit = 10)
    User.where.not(id: id)
        .where.not(id: friend_ids)
        .where.not(id: pending_sent_requests.pluck(:friend_id))
        .where.not(id: pending_received_requests.pluck(:user_id))
        .limit(limit)
  end
  
  # Общие друзья с другим пользователем
  def mutual_friends_with(other_user)
    User.where(id: friend_ids & other_user.friend_ids)
  end
  
  # Количество общих друзей
  def mutual_friends_count_with(other_user)
    mutual_friends_with(other_user).count
  end
  
  # -------------------------
  # МЕТОДЫ ДЛЯ ВИШЛИСТА
  # -------------------------
  
  def in_wishlist?(game)
    wishlists.exists?(game: game)
  end

  def wishlist_priority_for(game)
    wishlists.find_by(game_id: game.id)&.priority
  end
  
  # Все игры в вишлисте
  def wishlisted_games
    Game.joins(:wishlists).where(wishlists: { user_id: id })
  end
  
  # -------------------------
  # МЕТОДЫ ДЛЯ КОЛЛЕКЦИЙ
  # -------------------------
  
  def collections_statistics
    {
      total_collections: collections.count,
      total_games: collections.joins(:games).distinct.count(:game_id),
      average_games_per_collection: collections_count.zero? ? 0 : 
                                   (collections.joins(:games).distinct.count(:game_id).to_f / collections_count).round(1),
      most_common_genre: "Не определено" # Можно реализовать позже
    }
  end
  
  # -------------------------
  # ПРИВАТНЫЕ МЕТОДЫ
  # -------------------------
  
  private
  
  def create_profile
    Profile.create(user: self) unless profile.present?
  end
  
  def create_default_collections
    Collection.create_default_collections_for_user(self)
  end
end