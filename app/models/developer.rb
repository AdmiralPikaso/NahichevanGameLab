class Developer < ApplicationRecord
  
  validates :name, presence: true, uniqueness: true
  
  
  has_many :game_developers, dependent: :destroy
  has_many :games, through: :game_developers
  
  
  def name_with_country
    "#{name} (#{country})"
  end
end