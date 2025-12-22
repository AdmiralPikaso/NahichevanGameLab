class ProfilesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_profile, only: [:edit, :update]
  before_action :set_user, only: [:show]

  def index
    @profiles = Profile
                  .where(private: false)
                  .includes(:user)
                  .order(created_at: :desc)
  end

  def show
    @profile = @user.profile

    unless @profile
      redirect_to profiles_path, alert: "Профиль не найден"
      return
    end

    if @profile.private? && @user != current_user
      redirect_to profiles_path, alert: "Этот профиль приватный"
      return
    end

    @collections_count = @user.collections.count
  end

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

  private

  def set_user
    @user = User.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to profiles_path, alert: "Пользователь не найден"
  end

  def set_profile
    @profile = current_user.profile || current_user.build_profile
  end

  def profile_params
    params.require(:profile).permit(:bio, :private, :avatar)
  end
end
