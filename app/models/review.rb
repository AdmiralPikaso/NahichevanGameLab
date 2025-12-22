class Review < ApplicationRecord
  belongs_to :game
  belongs_to :user
  
  has_many :comments, dependent: :destroy
  has_many :likes, dependent: :destroy
  
  validates :title, presence: true, length: { minimum: 5, maximum: 100 }
  validates :content, presence: true, length: { minimum: 50, maximum: 5000 }
  validates :rating, numericality: { 
    only_integer: true, 
    greater_than_or_equal_to: 1, 
    less_than_or_equal_to: 10 
  }
  
  def liked_by?(user)
    likes.exists?(user: user)
  end
  
  def likes_count
    likes.count
  end
end