class Game < ApplicationRecord
  validates :title, presence: true, uniqueness: true
  validates :release_date, presence: true
  validates :metacritic_score, 
    numericality: { 
      only_integer: true,                  
      greater_than_or_equal_to: 0,          
      less_than_or_equal_to: 100             
    }, 
    allow_nil: true                          
  
  has_many :game_developers, dependent: :destroy
  has_many :developers, through: :game_developers
  has_many :reviews, dependent: :destroy
  has_many :ratings, dependent: :destroy
  
  has_many :collection_games, dependent: :destroy
  has_many :collections, through: :collection_games
  has_many :comments, through: :reviews
  
  def developer_names
    developers.pluck(:name).join(', ')
  end
  
  def average_rating
    ratings.average(:score)&.round(1) || 0.0
  end

  has_many :wishlists, dependent: :destroy
  has_many :wishlisted_by, through: :wishlists, source: :user
  
  # Метод для проверки, находится ли игра в вишлисте текущего пользователя
  def in_current_user_wishlist?
    return false unless Thread.current[:current_user]
    Thread.current[:current_user].in_wishlist?(self)
  end
  
  # Получить количество добавлений в вишлист по приоритетам
  def wishlist_stats
    Wishlist.where(game_id: id).group(:priority).count
  end
  
  # Самый популярный приоритет для этой игры
  def most_common_wishlist_priority
    stats = wishlist_stats
    stats.max_by { |_, count| count }&.first if stats.any?
  
  def rating_count
    ratings.count
  end
  
  def user_rating(user)
    ratings.find_by(user: user)&.score
  end
  
  def update_average_rating
    update_column(:average_rating, average_rating)
  end
  
  def reviewed_by?(user)
    reviews.exists?(user: user)
  end
  
  def user_review(user)
    reviews.find_by(user: user)
  end
end