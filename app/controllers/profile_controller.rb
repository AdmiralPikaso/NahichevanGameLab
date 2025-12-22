class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile_user, only: [:show, :collections, :friends, :stats]
  before_action :set_profile, only: [:edit, :update]

  # =========================
  # СПИСОК ПРОФИЛЕЙ
  # =========================
  def index
    @profiles = Profile
      .where(private: false)
      .includes(:user, user: :collections)
      .order(created_at: :desc)
  end

  # =========================
  # ПРОСМОТР ПРОФИЛЯ
  # =========================
  def show
    deny_access_if_private!

    @collections_count = @user.collections.count
    @games_count = @user.collections.joins(:games).distinct.count(:game_id)

    @top_collections = @user.collections
      .left_joins(:games)
      .group("collections.id")
      .select("collections.*, COUNT(games.id) AS games_count")
      .order("games_count DESC")
      .limit(3)

    @friendship_status = friendship_status
    @can_view_collections = can_view_collections?
  end

  # =========================
  # МОЙ ПРОФИЛЬ
  # =========================
  def me
    redirect_to profile_path(current_user.profile)
  end

  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to my_profile_path, notice: "Профиль обновлён"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # =========================
  # КОЛЛЕКЦИИ
  # =========================
  def collections
    deny_access_if_private!
    @collections = @user.collections.includes(:games)
  end

  # =========================
  # ДРУЗЬЯ
  # =========================
  def friends
    @friends = @user.accepted_friends
  end

  # =========================
  # СТАТИСТИКА
  # =========================
  def stats
    @stats = {
      collections: @user.collections.count,
      games: @user.collections.joins(:games).distinct.count(:game_id),
      friends: @user.accepted_friends.count
    }
  end

  # =========================
  private
  # =========================

  def set_profile_user
    @profile = Profile.find(params[:id])
    @user = @profile.user
  rescue ActiveRecord::RecordNotFound
    redirect_to profiles_path, alert: "Профиль не найден"
  end

  def set_profile
    @profile = current_user.profile || current_user.build_profile
  end

  def deny_access_if_private!
    if @profile.private? && @user != current_user
      redirect_to profiles_path, alert: "Профиль приватный"
    end
  end

  def friendship_status
    return nil unless Friendship.table_exists?
    current_user.friendship_status_with(@user)
  end

  def can_view_collections?
    @user == current_user ||
      (!@profile.private? && friendship_status == :friends)
  end

  def profile_params
    params.require(:profile).permit(:bio, :private, :avatar)
  end
end
