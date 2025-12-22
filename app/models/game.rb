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
  has_many :comments, through: :reviews
  
  def developer_names
    developers.pluck(:name).join(', ')
  end
  
  def average_rating
    ratings.average(:score)&.round(1) || 0.0
  end
  
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