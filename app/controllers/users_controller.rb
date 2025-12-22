class UsersController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show]
  before_action :set_collections, only: [:show]

  def index
    # Базовый запрос - все пользователи кроме текущего
    @users = User.where.not(id: current_user.id)
                 .includes(:profile, :collections)
                 .order(created_at: :desc)
    
    # Применяем фильтры
    case params[:filter]
    when 'recent'
      @users = @users.where("created_at >= ?", 30.days.ago)
    when 'with_bio'
      @users = @users.joins(:profile).where.not(profiles: { bio: [nil, ''] })
    when 'public'
      @users = @users.joins(:profile).where(profiles: { private: false })
    when 'with_collections'
      @users = @users.joins(:collections).distinct
    end
    
    # Поиск по email
    if params[:search].present?
      @users = @users.where("email ILIKE ?", "%#{params[:search]}%")
    end
    
    # Статистика для заголовка
    @total_users = @users.count
    @users_with_collections = @users.joins(:collections).distinct.count
  end

  def show
    # Статистика пользователя
    @games_count = @user.collections.joins(:games).distinct.count(:game_id)
    @collections_count = @user.collections.count
    
    # Популярные коллекции пользователя (по количеству игр)
    @top_collections = @user.collections
                           .left_joins(:games)
                           .group('collections.id')
                           .select('collections.*, COUNT(games.id) as games_count')
                           .order('games_count DESC')
                           .limit(3)
    
    # Проверка дружбы (если модель существует)
    if Friendship.table_exists?
      @friendship_status = current_user.friendship_status_with(@user)
    else
      @friendship_status = nil
    end
    
    # Можно ли просматривать коллекции?
    @can_view_collections = @user == current_user || 
                           (!@user.profile&.private? && @friendship_status == :friends)
  end

  private

  def set_user
    @user = User.includes(:profile, collections: [:games]).find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to users_path, alert: "Пользователь не найден"
  end

  def set_collections
    # Если пользователь может просматривать коллекции
    if @can_view_collections
      @public_collections = @user.collections
    else
      @public_collections = []
    end
  end
end