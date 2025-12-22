class Rating < ApplicationRecord
  belongs_to :game
  belongs_to :user
  
  validates :score, numericality: { 
    only_integer: true, 
    greater_than_or_equal_to: 1, 
    less_than_or_equal_to: 10 
  }
  validates :user_id, uniqueness: { scope: :game_id, message: "уже оценил эту игру" }
  
  after_save :update_game_average_rating
  
  private
  
  def update_game_average_rating
    game.update_average_rating
  end
end