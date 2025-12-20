class HomeController < ApplicationController
  def index
    if user_signed_in?
      redirect_to my_profile_path
    end
  end
end

