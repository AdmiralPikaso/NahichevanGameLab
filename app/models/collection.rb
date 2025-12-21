class Collection < ApplicationRecord
  belongs_to :user
  has_many :collection_games, dependent: :destroy
  has_many :games, through: :collection_games
  
  validates :name, presence: true, length: { minimum: 2, maximum: 100 }
  validates :description, length: { maximum: 500 }
  
  # Стандартные коллекции
  DEFAULT_COLLECTIONS = [
    { name: "Прохожу", description: "Игры, которые я сейчас прохожу" },
    { name: "Закончил", description: "Игры, которые я завершил" },
    { name: "На паузе", description: "Игры, которые я отложил" },
    { name: "Хочу пройти", description: "Игры, которые хочу начать" }
  ]
  
  def self.create_default_collections_for_user(user)
    DEFAULT_COLLECTIONS.each do |collection_data|
      user.collections.find_or_create_by(name: collection_data[:name]) do |collection|
        collection.description = collection_data[:description]
      end
    end
  end
end