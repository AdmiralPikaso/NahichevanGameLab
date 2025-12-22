class RatingsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_game

  def create
    @rating = @game.ratings.find_or_initialize_by(user: current_user)
    @rating.score = params[:score]

    if @rating.save
      respond_to do |format|
        format.html { redirect_to @game, notice: 'Оценка сохранена!' }
        format.json { render json: { 
          average_rating: @game.reload.average_rating,
          rating_count: @game.rating_count,
          user_rating: @rating.score 
        } }
      end
    else
      respond_to do |format|
        format.html { redirect_to @game, alert: @rating.errors.full_messages.join(', ') }
        format.json { render json: { errors: @rating.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  private

  def set_game
    @game = Game.find(params[:id])
  end
end