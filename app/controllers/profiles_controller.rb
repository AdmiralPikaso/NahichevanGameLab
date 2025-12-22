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
    prepare_collections
    prepare_stats
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
    @profile = Profile.includes(user: { collections: :games }).find(params[:id])
    @user = @profile.user
  end

  def prepare_collections
    @can_view_collections =
      @user == current_user ||
      (!@profile.private? && current_user.friend_with?(@user))

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

    if Friendship.table_exists?
      @friendship_status = current_user.friendship_status_with(@user)
    end
  end

  def profile_params
    params.require(:profile).permit(:bio, :private, :avatar)
  end
end
