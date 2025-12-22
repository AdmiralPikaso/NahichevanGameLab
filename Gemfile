source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

# Укажите версию Ruby
ruby "3.4.8"

# Основные гемы
gem "rails", "~> 8.1.1"
gem "propshaft"
gem "pg", "~> 1.1"
gem "puma", ">= 5.0"
gem "importmap-rails"
gem "turbo-rails"
gem "stimulus-rails"
gem "jbuilder"

# Аутентификация
gem "devise"

# Обработка изображений
gem "mini_magick"
# gem "image_processing", "~> 1.2"  # Временно закомментируйте, если есть проблемы с VIPS

# Кэширование и очереди
gem "solid_cache"
gem "solid_queue"
gem "solid_cable"

# Оптимизация
gem "bootsnap", require: false
gem "thruster", require: false

# Для Windows
gem "tzinfo-data", platforms: [:mingw, :mswin, :x64_mingw, :jruby]

# Деплой (опционально)
# gem "kamal", require: false

group :development do
  gem "letter_opener"
  gem "web-console"
  
  # Замените debug на byebug для Windows
  gem "byebug", platforms: [:mingw, :mswin, :x64_mingw]
end

group :development, :test do
  # Используйте byebug вместо debug для совместимости с Windows
  # gem "debug", platforms: %i[ mri windows ], require: "debug/prelude"  # Закомментируйте
  
  # Аудит безопасности
  gem "bundler-audit", require: false
  gem "brakeman", require: false
  
  # Стиль кода
  gem "rubocop-rails-omakase", require: false
end

group :test do
  gem "capybara"
  gem "selenium-webdriver"
end