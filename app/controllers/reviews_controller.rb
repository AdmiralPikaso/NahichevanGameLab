class ReviewsController < ApplicationController
  before_action :authenticate_user!, except: [:index, :show]
  before_action :set_review, only: [:show, :edit, :update, :destroy]
  before_action :set_game, only: [:new, :create, :index]
  before_action :authorize_user, only: [:edit, :update, :destroy]

  def index
    @reviews = @game.reviews.includes(:user, :likes, :comments)
                    .order(created_at: :desc)
  end

  def show
    @comments = @review.comments.includes(:user).order(created_at: :desc)
    @comment = Comment.new
  end

  def new
    @review = @game.reviews.new
  end

  def edit
  end

  def create
    @review = @game.reviews.new(review_params)
    @review.user = current_user

    if @review.save
      redirect_to review_path(@review), 
                  notice: 'Рецензия успешно создана!'
    else
      render :new
    end
  end

  def update
    if @review.update(review_params)
      redirect_to review_path(@review), 
                  notice: 'Рецензия успешно обновлена!'
    else
      render :edit
    end
  end

  def destroy
    @review.destroy
    redirect_to my_reviews_path, 
                notice: 'Рецензия успешно удалена!'
  end

def my_reviews
  @reviews = current_user.reviews
                         .includes(:game)  # УБРАЛИ :likes и :comments
                         .order(created_at: :desc)
end

  private

  def set_review
    @review = Review.find(params[:id])
  end

  def set_game
    @game = Game.find(params[:game_id]) if params[:game_id]
  end

  def authorize_user
    redirect_to root_path, alert: 'Недостаточно прав' unless @review.user == current_user || current_user.admin?
  end

  def review_params
    params.require(:review).permit(:title, :content, :rating)
  end
end