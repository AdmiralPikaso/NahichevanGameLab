class Friendship < ApplicationRecord
  # Отношения
  belongs_to :user
  belongs_to :friend, class_name: 'User'
  
  # Валидации
  validates :user_id, uniqueness: { 
    scope: :friend_id, 
    message: "Вы уже отправили заявку этому пользователю" 
  }
  
  # ВАЖНО: Добавляем валидацию на обратную связь
  validate :cannot_have_duplicate_relationships
  
  validates :status, inclusion: { in: %w[pending accepted rejected] }
  
  # Проверка, что нельзя добавить себя в друзья
  validate :cannot_add_self
  
  # Callbacks
  before_validation :set_default_status, on: :create
  
  # Scopes
  scope :pending, -> { where(status: 'pending') }
  scope :accepted, -> { where(status: 'accepted') }
  scope :rejected, -> { where(status: 'rejected') }
  
  # Scope для поиска дружбы между двумя пользователями
  scope :between, ->(user1, user2) do
    where(
      "(user_id = :user1 AND friend_id = :user2) OR (user_id = :user2 AND friend_id = :user1)",
      { user1: user1.id, user2: user2.id }
    )
  end
  
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
  
  # Действия со статусами
  def accept!
    update!(status: 'accepted')
  end
  
  def reject!
    update!(status: 'rejected')
  end
  
  # Вспомогательные методы
  def involves?(user)
    user_id == user.id || friend_id == user.id
  end
  
  def other_user(current_user)
    user_id == current_user.id ? friend : user
  end
  
  # Получить пользователя, который отправил заявку
  def requester
    user
  end
  
  # Получить пользователя, который получил заявку
  def receiver
    friend
  end
  
  # Проверить, является ли пользователь отправителем заявки
  def requester?(user)
    user_id == user.id
  end
  
  # Проверить, является ли пользователь получателем заявки
  def receiver?(user)
    friend_id == user.id
  end
  
  private
  
  def cannot_add_self
    if user_id == friend_id
      errors.add(:friend, "Нельзя добавить себя в друзья")
    end
  end
  
  def set_default_status
    self.status ||= 'pending'
  end
  
  # ВАЖНО: Проверяем, что не существует обратной связи
  def cannot_have_duplicate_relationships
    return if new_record?
    
    # Ищем существующую дружбу в обратном направлении
    existing = Friendship.where(
      user_id: friend_id,
      friend_id: user_id
    ).where.not(id: id).first
    
    if existing
      errors.add(:base, "Между вами уже есть отношения")
    end
  end
end