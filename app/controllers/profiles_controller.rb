class ProfilesController < ApplicationController
  before_action :authenticate_user!
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

    # Инициализируем счетчики
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
  
    # Подготавливаем статистику пользователя
    prepare_stats
    
    # Статистика пользователя (используем prepare_stats вместо calculate_user_stats)
    # Получаем значения из @collections_count и @games_count
    @user_stats = {
      collections_count: @collections_count,
      games_count: @games_count
    }
    
    # Популярные коллекции (первые 3 по количеству игр)
    @top_collections = @user.collections
                           .left_joins(:games)
                           .group('collections.id')
                           .select('collections.*, COUNT(games.id) as games_count')
                           .order('games_count DESC')
                           .limit(3)
    
    # Проверяем статус дружбы (если не текущий пользователь)
    if @user != current_user
      # Получаем статус дружбы, если доступна модель Friendship
      if Friendship.table_exists? && @user.respond_to?(:friendship_status_with)
        @friendship_status = current_user.friendship_status_with(@user)
      else
        @friendship_status = get_friendship_status(@user) rescue nil
      end
      
      # Может ли пользователь просматривать коллекции?
      @can_view_collections = !@profile.private? || @friendship_status == :friends
    else
      @friendship_status = nil
      @can_view_collections = true
    end
    
    # Подготавливаем коллекции для отображения
    prepare_collections
  end

  # 📌 МОЙ ПРОФИЛЬ
  def me
    redirect_to profile_path(current_user.profile)
  end

  # 📌 РЕДАКТИРОВАНИЕ
  def edit
    redirect_to root_path, alert: "Нет доступа" unless @profile.user == current_user
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
    @profile =
      if params[:id].present?
        Profile.includes(user: { collections: :games }).find(params[:id])
      else
        current_user.profile
      end

    @user = @profile.user
  end

  def prepare_collections
    @can_view_collections ||=
      @user == current_user ||
      (!@profile.private? && current_user.friend_with?(@user)) rescue false

    @public_collections = []
    @top_collections = []

    return unless @can_view_collections

    @public_collections = @user.collections

    @top_collections = @user.collections
      .left_joins(:games)
      .group("collections.id")
      .select("collections.*, COUNT(games.id) AS games_count")
      .order("games_count DESC")
      .limit(3)
  end

  def prepare_stats
    @collections_count = @user.collections.count
    @games_count = @user.collections.joins(:games).distinct.count(:game_id)

    # Инициализируем статус дружбы, если нужно
    if @user != current_user
      if Friendship.table_exists?
        @friendship_status ||= current_user.friendship_status_with(@user) rescue nil
      end
    end
  end

  # Метод для определения статуса дружбы (если используется в коде)
  def get_friendship_status(user)
    # Проверяем, является ли пользователь другом
    if Friendship.table_exists? && current_user.friends.include?(user)
      return :friends
    end
    
    # Проверяем, отправлена ли заявка
    if Friendship.table_exists? && current_user.sent_friend_requests.where(friend: user).exists?
      return :request_sent
    end
    
    # Проверяем, получена ли заявка
    if Friendship.table_exists? && current_user.received_friend_requests.where(user: user).exists?
      return :request_received
    end
    
    # Если ничего не подошло
    return :none
  end

  def profile_params
    params.require(:profile).permit(:bio, :private, :avatar)
  end
end