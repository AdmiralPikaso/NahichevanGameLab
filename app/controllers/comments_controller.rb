class CommentsController < ApplicationController
  before_action :authenticate_user!, except: [:index]
  before_action :set_review, except: [:destroy]
  before_action :set_comment, only: [:destroy]

  def index
    @comments = @review.comments.includes(:user).order(created_at: :desc)
    render json: @comments
  end

  def create
    @comment = @review.comments.new(comment_params)
    @comment.user = current_user

    respond_to do |format|
      if @comment.save
        format.html { redirect_to review_path(@review), notice: 'Комментарий добавлен!' }
        format.json { render json: @comment, status: :created }
        format.turbo_stream
      else
        format.html { redirect_to review_path(@review), alert: @comment.errors.full_messages.join(', ') }
        format.json { render json: @comment.errors, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    @review = @comment.review
    if @comment.user == current_user || current_user.admin?
      @comment.destroy
      respond_to do |format|
        format.html { redirect_to review_path(@review), notice: 'Комментарий удален!' }
        format.json { head :no_content }
        format.turbo_stream
      end
    else
      redirect_to review_path(@review), 
                  alert: 'Недостаточно прав для удаления комментария'
    end
  end

  private

  def set_review
    @review = Review.find(params[:review_id])
  end

  def set_comment
    @comment = Comment.find(params[:id])
  end

  def comment_params
    params.require(:comment).permit(:content)
  end
end