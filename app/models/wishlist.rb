class Wishlist < ApplicationRecord
  belongs_to :user
  belongs_to :game
  
  validates :user_id, uniqueness: { scope: :game_id, message: "уже есть в вашем вишлисте" }
  
  # Исправленный enum
  enum :priority, {
    low: 0,
    medium: 1,
    high: 2
  }, default: :medium, suffix: true
  
  # Scopes
  scope :sorted_by_priority, -> { order(priority: :desc, created_at: :desc) }
  scope :with_high_priority, -> { where(priority: :high) }
  scope :recently_added, -> { where("created_at >= ?", 30.days.ago) }
  
  # Делегирование для удобства
  delegate :title, :cover_url, :metacritic_score, :release_date, to: :game
  
  # Метод для получения цвета приоритета
  def priority_color
    case priority
    when 'low'
      'secondary'
    when 'medium'
      'primary'
    when 'high'
      'warning'
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
    else
      'Не указан'
    end
  end
  
  # Метод для проверки наличия игры в вишлисте пользователя
  def self.in_wishlist?(user, game)
    user.wishlists.exists?(game: game)
  end
  
  # Метод для получения полного имени приоритета с иконкой
  def priority_full_name
    "#{priority_icon} #{priority_name}"
  end
end