class ProfilesController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_profile, only: [:show, :edit, :update]

  # 📌 СПИСОК ПУБЛИЧНЫХ ПРОФИЛЕЙ
  def index
    @profiles = Profile
      .includes(:user)
      .where(private: [false, nil])
      .order(created_at: :desc)

    # статистика (для карточек сверху)
    @total_profiles = @profiles.count
    @with_collections = @profiles
      .joins(user: :collections)
      .distinct
      .count
    @with_bio = @profiles.where.not(bio: [nil, ""]).count
    @recent = @profiles
      .where("profiles.created_at >= ?", 30.days.ago)
      .count
  end

  # 📌 ПРОСМОТР ПРОФИЛЯ
  def show
    unless @user
      redirect_to profiles_path, alert: "Пользователь не найден"
      return
    end

    @profile = @user.profile
    unless @profile
      redirect_to profiles_path, alert: "Профиль не найден"
      return
    end
    
    # Проверяем доступ к приватному профилю
    if @profile.private? && @user != current_user && !current_user.friends_with?(@user)
      redirect_to profiles_path, alert: "Этот профиль приватный. Только друзья могут его просматривать."
      return
    end
  
    # Подготавливаем статистику пользователя
    prepare_stats
    
    # Определяем статус дружбы (если не текущий пользователь)
    if @user != current_user
      @friendship_status = current_user.friendship_status_with(@user)
    else
      @friendship_status = :self
    end
    
    # Может ли пользователь просматривать коллекции?
    @can_view_collections = @user == current_user || 
                           !@profile.private? || 
                           @friendship_status == :friends
    
    # Подготавливаем коллекции для отображения
    if @can_view_collections
      @top_collections = @user.collections
                             .left_joins(:games)
                             .group('collections.id')
                             .select('collections.*, COUNT(games.id) as games_count')
                             .order('games_count DESC')
                             .limit(3)
    else
      @top_collections = []
    end
  end

  # 📌 МОЙ ПРОФИЛЬ
  def me
    redirect_to profile_path(current_user)
  end

  # 📌 РЕДАКТИРОВАНИЕ
  def edit
    unless @profile.user == current_user
      redirect_to root_path, alert: "Нет доступа"
    end
  end

  def update
    if @profile.update(profile_params)
      redirect_to my_profile_path, notice: "Профиль обновлён"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_profile
    if params[:id].present?
      @user = User.includes(profile: [], collections: [:games]).find(params[:id])
      @profile = @user.profile
    else
      @user = current_user
      @profile = current_user.profile
    end
    
    unless @profile
      redirect_to profiles_path, alert: "Профиль не найден"
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to profiles_path, alert: "Пользователь не найден"
  end

  def prepare_stats
    @collections_count = @user.collections.count
    @games_count = @user.collections.joins(:games).distinct.count(:game_id)
  end

  def profile_params
    params.require(:profile).permit(:bio, :private, :avatar)
  end
end