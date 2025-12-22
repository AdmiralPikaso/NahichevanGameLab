class ProfilesController < ApplicationController
  before_action :authenticate_user!

  before_action :set_profile, only: [:show]
  before_action :set_my_profile, only: [:me, :edit, :update]
  before_action :prepare_collections, only: [:show]

  # ====== СПИСОК ПУБЛИЧНЫХ ПРОФИЛЕЙ ======
  def index
    @profiles = Profile
      .joins(:user)
      .where(private: false)
      .includes(:user)
      .order(created_at: :desc)
  end

  # ====== ПРОСМОТР ЧУЖОГО ПРОФИЛЯ ======
  def show
    # вся логика вынесена в before_action
  end

  # ====== МОЙ ПРОФИЛЬ ======
  def me
    redirect_to profile_path(@profile)
  end

  # ====== РЕДАКТИРОВАНИЕ МОЕГО ПРОФИЛЯ ======
  def edit
  end

  def update
    if @profile.update(profile_params)
      redirect_to my_profile_path, notice: "Профиль успешно обновлён"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  # ====== ЧУЖОЙ ПРОФИЛЬ ======
  def set_profile
    @profile = Profile.find(params[:id])
    @user = @profile.user

    @collections_count = @user.collections.count
    @games_count = @user.collections.joins(:games).distinct.count(:game_id)

    if Friendship.table_exists?
      @friendship_status = current_user.friendship_status_with(@user)
    end
  end

  # ====== МОЙ ПРОФИЛЬ ======
  def set_my_profile
    @profile = current_user.profile
    @user = current_user
  end

  # ====== КОЛЛЕКЦИИ ======
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
      .group('collections.id')
      .select('collections.*, COUNT(games.id) AS games_count')
      .order('games_count DESC')
      .limit(3)
  end

  def profile_params
    params.require(:profile).permit(:bio, :private, :avatar)
  end
end
