class Profile < ApplicationRecord
  belongs_to :user
  has_one_attached :avatar
  
  has_many :reviews, through: :user
  has_many :ratings, through: :user
  has_many :comments, through: :user
  has_many :likes, through: :user
  
  def reviews_count
    reviews.count
  end
  
  def average_game_rating
    ratings.average(:score)&.round(1) || 0.0
  end
  
  def total_likes_received
    reviews.joins(:likes).count
  end
  
  def recent_reviews(limit = 5)
    reviews.order(created_at: :desc).limit(limit)
  end
end