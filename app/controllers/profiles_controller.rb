class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show]
  before_action :set_profile, only: [:edit, :update]
  before_action :set_user_collections, only: [:show]

  def index
    # Базовый запрос - только публичные профили с предзагрузкой данных
    @profiles = Profile.where(private: false)
                      .includes(:user, user: [:collections])
                      .order(created_at: :desc)
    
    # Применяем фильтры
    apply_filters
    apply_search
    
    # Статистика для представления
    @stats = {
      total: @profiles.count,
      with_collections: @profiles.joins(user: :collections).distinct.count,
      with_bio: @profiles.where.not(bio: [nil, '']).count,
      recent: @profiles.joins(:user).where("users.created_at >= ?", 30.days.ago).count
    }
  end

  def show
    unless @user
      redirect_to profiles_path, alert: "Пользователь не найден"
      return
    end

    @collections_count ||= 0
    @games_count ||= 0

    @profile = @user.profile
    unless @profile
      redirect_to profiles_path, alert: "Профиль не найден"
      return
    end
    
    if @profile.private? && @user != current_user
      redirect_to profiles_path, alert: "Этот профиль приватный"
      return
    end
  
    # Статистика пользователя
    @user_stats = calculate_user_stats(@user)
    
    # Популярные коллекции (первые 3 по количеству игр)
    @top_collections = @user.collections
                           .left_joins(:games)
                           .group('collections.id')
                           .select('collections.*, COUNT(games.id) as games_count')
                           .order('games_count DESC')
                           .limit(3)
    
    # Проверяем статус дружбы (если не текущий пользователь)
    if @user != current_user
      @friendship_status = get_friendship_status(@user)
      
      # Может ли пользователь просматривать коллекции?
      @can_view_collections = !@profile.private? || @friendship_status == :friends
    else
      @friendship_status = nil
      @can_view_collections = true
    end
  end

  def me
    redirect_to profile_path(current_user)
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to my_profile_path, notice: "Профиль успешно обновлен"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.includes(:collections, collections: [:games]).find_by(id: params[:id])
  end

  def set_profile
    @profile = current_user.profile || current_user.build_profile
  end

  def set_user_collections
    return unless @user
    
    # Если это текущий пользователь или можно просматривать коллекции
    if @user == current_user || @can_view_collections
      @public_collections = @user.collections.includes(:games)
    else
      @public_collections = []
    end
  end

  def profile_params
    params.require(:profile).permit(:bio, :private, :avatar)
  end

  def get_friendship_status(user)
    return nil unless user_signed_in?
    
    # Проверяем, существует ли модель Friendship
    return nil unless Friendship.table_exists?
    
    friendship = Friendship.find_by(user_id: current_user.id, friend_id: user.id) ||
                 Friendship.find_by(user_id: user.id, friend_id: current_user.id)
    
    return nil unless friendship
    
    if friendship.pending?
      if friendship.user_id == current_user.id
        :request_sent
      else
        :request_received
      end
    elsif friendship.accepted?
      :friends
    else
      nil
    end
  end

  def apply_filters
    case params[:filter]
    when 'with_collections'
      @profiles = @profiles.joins(user: :collections).distinct
    when 'active'
      @profiles = @profiles.joins(:user).where("users.updated_at >= ?", 7.days.ago)
    when 'recent'
      @profiles = @profiles.joins(:user).where("users.created_at >= ?", 30.days.ago)
    when 'with_bio'
      @profiles = @profiles.where.not(bio: [nil, ''])
    end
  end

  def apply_search
    if params[:search].present?
      @profiles = @profiles.joins(:user).where(
        "users.email ILIKE :search OR profiles.bio ILIKE :search", 
        search: "%#{params[:search]}%"
      )
    end
  end

  def calculate_user_stats(user)
    {
      collections_count: user.collections.count,
      games_in_collections: user.collections.joins(:games).distinct.count(:game_id),
      total_games_count: Game.count, # Общее количество игр в системе
      collection_coverage: calculate_coverage(user),
      friends_count: user.accepted_friends.count,
      joined_days_ago: (Date.today - user.created_at.to_date).to_i
    }
  end

  def calculate_coverage(user)
    total_games = Game.count
    return 0 if total_games.zero?
    
    user_games = user.collections.joins(:games).distinct.count(:game_id)
    ((user_games.to_f / total_games) * 100).round(1)
  end
end