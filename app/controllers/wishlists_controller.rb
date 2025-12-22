class WishlistsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_wishlist, only: [:destroy, :update]
  before_action :set_game, only: [:create]

  def index
    @wishlists = current_user.wishlists
                             .includes(game: [:developers])
                             .sorted_by_priority
                             
    # Статистика
    @total_games = @wishlists.count
    @high_priority_count = @wishlists.with_high_priority.count
    @estimated_cost = calculate_estimated_cost
    
    # Группировка по приоритету
    @grouped_wishlists = @wishlists.group_by(&:priority)
    
    # Для фильтрации
    @priorities = Wishlist.priorities.keys
    @selected_priority = params[:priority]
    
    if @selected_priority.present? && @priorities.include?(@selected_priority)
      @wishlists = @wishlists.where(priority: @selected_priority)
    end
    
    # Сортировка по приоритету
    @sorted_priorities = ['must_have', 'high', 'medium', 'low']
  end

  def create
    # Проверяем, не добавлена ли уже игра
    if current_user.in_wishlist?(@game)
      respond_to do |format|
        format.html { redirect_back fallback_location: games_path, alert: "Игра уже в вашем вишлисте" }
        format.json { render json: { error: "Игра уже в вишлисте" }, status: :unprocessable_entity }
      end
      return
    end
    
    @wishlist = current_user.wishlists.new(
      game: @game,
      priority: params[:priority] || 'medium',
      notes: params[:notes]
    )
    
    if @wishlist.save
      respond_to do |format|
        format.html { redirect_back fallback_location: games_path, notice: "Игра добавлена в вишлист!" }
        format.json { render json: { success: true, wishlist: @wishlist } }
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: games_path, alert: "Ошибка: #{@wishlist.errors.full_messages.join(', ')}" }
        format.json { render json: { error: @wishlist.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def update
    if @wishlist.update(wishlist_params)
      respond_to do |format|
        format.html { redirect_to wishlists_path, notice: "Вишлист обновлен" }
        format.json { render json: { success: true, wishlist: @wishlist } }
      end
    else
      respond_to do |format|
        format.html { redirect_to wishlists_path, alert: "Ошибка обновления" }
        format.json { render json: { error: @wishlist.errors.full_messages }, status: :unprocessable_entity }
      end
    end
  end

  def destroy
    game_title = @wishlist.game.title
    @wishlist.destroy
    
    respond_to do |format|
      format.html { redirect_back fallback_location: wishlists_path, notice: "#{game_title} удалена из вишлиста" }
      format.json { render json: { success: true } }
    end
  end
  
  # Быстрое добавление в вишлист
  def quick_add
    @game = Game.find(params[:game_id])
    priority = params[:priority] || 'medium'
    
    unless current_user.in_wishlist?(@game)
      current_user.wishlists.create(game: @game, priority: priority)
      notice = "Игра добавлена в вишлист"
    else
      notice = "Игра уже в вашем вишлисте"
    end
    
    redirect_back fallback_location: games_path, notice: notice
  end

  private

  def set_wishlist
    @wishlist = current_user.wishlists.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to wishlists_path, alert: "Запись не найдена"
  end

  def set_game
    @game = Game.find(params[:game_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to games_path, alert: "Игра не найдена"
  end

  def wishlist_params
    params.require(:wishlist).permit(:priority, :notes)
  end
  
  def calculate_estimated_cost
    # Примерная оценка стоимости
    average_price = 29.99
    @wishlists.count * average_price
  end
end