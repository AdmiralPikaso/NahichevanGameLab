class CollectionsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_collection, only: [:show, :edit, :update, :destroy, :add_game, :remove_game]
  before_action :check_ownership, only: [:edit, :update, :destroy, :add_game, :remove_game]

  def index
    @collections = current_user.collections.includes(:games).order(created_at: :desc)
    @total_games = @collections.sum { |c| c.games.count }
  end

  def show
    @games = @collection.games.includes(:developers)
    @available_games = Game.where.not(id: @collection.game_ids).order(title: :asc)
  end

  def new
    @collection = current_user.collections.new
  end

  def edit
  end

  def create
    @collection = current_user.collections.new(collection_params)
    
    if @collection.save
      redirect_to collection_path(@collection), notice: "Коллекция успешно создана"
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @collection.update(collection_params)
      redirect_to collection_path(@collection), notice: "Коллекция успешно обновлена"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    @collection.destroy
    redirect_to collections_path, notice: "Коллекция удалена"
  end

  def add_game
    @game = Game.find(params[:game_id])
    
    if @collection.games.include?(@game)
      redirect_to collection_path(@collection), alert: "Игра уже есть в коллекции"
      return
    end
    
    @collection.games << @game
    redirect_to collection_path(@collection), notice: "Игра добавлена в коллекцию"
  end

  def remove_game
    @game = Game.find(params[:game_id])
    @collection.games.delete(@game)
    redirect_to collection_path(@collection), notice: "Игра удалена из коллекции"
  end

  private

  def set_collection
    @collection = Collection.find(params[:id])
  end

  def check_ownership
    unless @collection.user == current_user
      redirect_to collections_path, alert: "У вас нет доступа к этой коллекции"
    end
  end

  def collection_params
    params.require(:collection).permit(:name, :description)
  end
end