# app/models/like.rb
class Like < ApplicationRecord
  belongs_to :review
  belongs_to :user
  
  validates :user_id, uniqueness: { scope: :review_id, message: "уже лайкнул эту рецензию" }
end