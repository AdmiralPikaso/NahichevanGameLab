class LikesController < ApplicationController
  before_action :authenticate_user!
  before_action :set_review, only: [:create]
  before_action :set_like, only: [:destroy]

  def create
    @like = @review.likes.find_or_create_by(user: current_user)
    
    respond_to do |format|
      format.html { redirect_back fallback_location: review_path(@review) }
      format.json { render json: { likes_count: @review.likes_count } }
      format.turbo_stream
    end
  end

  def destroy
    @review = @like.review
    @like.destroy
    
    respond_to do |format|
      format.html { redirect_back fallback_location: review_path(@review) }
      format.json { render json: { likes_count: @review.likes_count } }
      format.turbo_stream
    end
  end

  private

  def set_review
    @review = Review.find(params[:review_id])
  end

  def set_like
    @like = current_user.likes.find(params[:id])
  end
end