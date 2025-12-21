class CollectionGame < ApplicationRecord
  belongs_to :collection
  belongs_to :game
  
  validates :game_id, uniqueness: { scope: :collection_id, message: "уже есть в этой коллекции" }
end