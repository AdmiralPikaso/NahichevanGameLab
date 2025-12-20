class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: :show
  before_action :check_privacy, only: :show

  # ===== МОЙ ПРОФИЛЬ =====
  def me
    @profile = current_user.profile
    render :show
  end

  def edit
    @profile = current_user.profile
  end

  def update
    @profile = current_user.profile

    if @profile.update(profile_params)
      redirect_to my_profile_path, notice: "Профиль обновлён"
    else
      render :edit
    end
  end

  # ===== ЧУЖОЙ ПРОФИЛЬ =====
  def show
    # @profile найден по id
  end

  # ===== СПИСОК =====
  def index
    @profiles = Profile.includes(:user)
  end

  private

  def set_profile
    @profile = Profile.find(params[:id])
  end

  def profile_params
    params.require(:profile).permit(:bio, :private, :avatar)
  end

  def check_privacy
    return if @profile == current_user.profile
    return unless @profile.private?

    redirect_to profiles_path, alert: "Профиль закрыт"
  end
end














