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
  
 
  
  
  def developer_names
    developers.pluck(:name).join(', ')
  end
  
 
  def average_rating
   
    ratings.average(:score)&.round(1) || 0.0
  end
end