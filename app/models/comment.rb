class Comment < ApplicationRecord
  belongs_to :review
  belongs_to :user
  
  validates :content, presence: true, length: { minimum: 2, maximum: 1000 }
  
  scope :latest, -> { order(created_at: :desc) }
end