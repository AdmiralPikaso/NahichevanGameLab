class Friendship < ApplicationRecord
  # Отношения
  belongs_to :user
  belongs_to :friend, class_name: 'User'
  
  # Валидации
  validates :user_id, uniqueness: { scope: :friend_id, message: "Вы уже отправили заявку этому пользователю" }
  validates :status, inclusion: { in: %w[pending accepted rejected] }
  
  # Проверка, что нельзя добавить себя в друзья
  validate :cannot_add_self
  
  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :accepted, -> { where(status: 'accepted') }
  scope :rejected, -> { where(status: 'rejected') }
  
  # Методы статусов
  def pending?
    status == 'pending'
  end
  
  def accepted?
    status == 'accepted'
  end
  
  def rejected?
    status == 'rejected'
  end
  
  private
  
  def cannot_add_self
    errors.add(:friend, "Нельзя добавить себя в друзья") if user_id == friend_id
  end
end