class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_user, only: [:show]
  before_action :prepare_profile_data, only: [:show]

  def index
    @profiles = Profile
      .joins(:user)
      .where(private: false)
      .includes(:user)
      .order(created_at: :desc)
  end

  def show
    # вся логика вынесена в before_action
  end

  def me
    redirect_to profile_path(current_user.profile)
  end

  private

  def set_user
    @user = User
      .includes(:profile, collections: :games)
      .find(params[:id])

    @profile = @user.profile
  rescue ActiveRecord::RecordNotFound
    redirect_to profiles_path, alert: "Профиль не найден"
  end

  def prepare_profile_data
    # --- статистика ---
    @collections_count = @user.collections.count
    @games_count       = @user.collections.joins(:games).distinct.count(:game_id)

    # --- дружба ---
    if Friendship.table_exists?
      @friendship_status = current_user.friendship_status_with(@user)
    else
      @friendship_status = nil
    end

    # --- доступ к коллекциям ---
    @can_view_collections =
      @user == current_user ||
      (!@profile.private? && @friendship_status == :friends)

    # --- ВСЕГДА массивы ---
    @public_collections = []
    @top_collections    = []

    return unless @can_view_collections

    @public_collections = @user.collections

    @top_collections = @user.collections
      .left_joins(:games)
      .group('collections.id')
      .select('collections.*, COUNT(games.id) AS games_count')
      .order('games_count DESC')
      .limit(3)
  end
end
