class GameDeveloper < ApplicationRecord
  
  belongs_to :game
  belongs_to :developer
  
  
  validates :developer_id, uniqueness: { scope: :game_id }
end