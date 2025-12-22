class Wishlist < ApplicationRecord
  belongs_to :user
  belongs_to :game
  
  validates :user_id, uniqueness: { scope: :game_id, message: "уже есть в вашем вишлисте" }
  
  # Исправленный enum - используйте либо целые числа, либо строки
  enum :priority, {
    low: 0,
    medium: 1,
    high: 2,
    must_have: 3
  }, default: :medium
  
  # Scopes
  scope :sorted_by_priority, -> { order(priority: :desc, created_at: :desc) }
  scope :with_high_priority, -> { where(priority: [:high, :must_have]) }
  scope :recently_added, -> { where("created_at >= ?", 30.days.ago) }
  
  # Метод для получения цвета приоритета
  def priority_color
    case priority
    when 'low'
      'secondary'
    when 'medium'
      'info'
    when 'high'
      'warning'
    when 'must_have'
      'danger'
    else
      'light'
    end
  end
  
  # Метод для получения иконки приоритета
  def priority_icon
    case priority
    when 'low'
      '⬇️'
    when 'medium'
      '↔️'
    when 'high'
      '⬆️'
    when 'must_have'
      '🔥'
    else
      '📌'
    end
  end
  
  # Метод для получения human-readable названия приоритета
  def priority_name
    case priority
    when 'low'
      'Низкий'
    when 'medium'
      'Средний'
    when 'high'
      'Высокий'
    when 'must_have'
      'Обязательно'
    else
      'Не указан'
    end
  end
end