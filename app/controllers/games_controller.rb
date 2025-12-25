class GamesController < ApplicationController
  before_action :set_game, only: [:show, :edit, :update, :destroy, :add_to_wishlist, :remove_from_wishlist]
  before_action :authenticate_user!, only: [:add_to_wishlist, :remove_from_wishlist, :toggle_wishlist]
  before_action :set_current_user_for_models, only: [:index, :show]
  
  def index
    # Базовый запрос с предзагрузкой ВСЕГО, включая cover attachment
    @games = Game.with_attached_cover
                 .includes(:developers, :wishlists, :collections)
                 .order(created_at: :desc)
    
    # Поиск
    apply_search_filter if params[:search].present?
    
    # Фильтр по вишлисту (только для авторизованных)
    apply_wishlist_filter if user_signed_in? && params[:filter].present?
    
    # Сортировка
    apply_sorting if params[:sort].present?
    
    # Пагинация (опционально)
    # @games = @games.page(params[:page]).per(12)
    
    # Статистика для представления
    @stats = {
      total: @games.count,
      with_high_rating: @games.where("metacritic_score >= ?", 80).count,
      in_wishlists: @games.joins(:wishlists).distinct.count,
      upcoming: @games.where("release_date > ?", Date.today).count
    }
  end
  
  def show
    # Информация о вишлисте для текущего пользователя
    if user_signed_in?
      @in_wishlist = current_user.wishlists.exists?(game: @game)
      @wishlist_item = current_user.wishlists.find_by(game: @game)
    end
    
    # Статистика игры
    @game_stats = {
      wishlist_count: @game.wishlists.count,
      collection_count: @game.collections.count,
      average_rating: @game.metacritic_score || 'Нет оценки'
    }
    
    # Похожие игры (по разработчикам)
    @similar_games = Game.where.not(id: @game.id)
                         .joins(:developers)
                         .where(developers: { id: @game.developer_ids })
                         .distinct
                         .limit(3)
  end
  
  def new
    @game = Game.new
  end
  
  def create
    @game = Game.new(game_params)
    
    if @game.save
      redirect_to @game, notice: 'Игра успешно создана!'
    else
      render :new
    end
  end
  
  def edit
    # Проверяем права доступа (опционально)
    unless can_edit_game?
      redirect_to games_path, alert: 'У вас нет прав для редактирования этой игры'
    end
  end
  
  def update
    if @game.update(game_params)
      redirect_to @game, notice: 'Игра успешно обновлена!'
    else
      render :edit
    end
  end
  
  def destroy
    # Проверяем права доступа (опционально)
    unless can_delete_game?
      redirect_to games_path, alert: 'У вас нет прав для удаления этой игры'
      return
    end
    
    @game.destroy
    redirect_to games_url, notice: 'Игра успешно удалена.'
  end
  
  # Действия для вишлиста
  
  def add_to_wishlist
    priority = params[:priority] || 'medium'
    notes = params[:notes]
    
    # Проверяем, не добавлена ли уже игра
    if current_user.wishlists.exists?(game: @game)
      respond_to do |format|
        format.html { redirect_back fallback_location: @game, alert: 'Игра уже в вашем вишлисте' }
        format.json { render json: { error: 'Игра уже в вишлисте' }, status: :unprocessable_entity }
        format.js   { render js: "alert('Игра уже в вишлисте');" }
      end
      return
    end
    
    # Создаем запись в вишлисте
    @wishlist = current_user.wishlists.new(
      game: @game,
      priority: priority,
      notes: notes
    )
    
    if @wishlist.save
      respond_to do |format|
        format.html { redirect_back fallback_location: @game, notice: 'Игра добавлена в вишлист!' }
        format.json { render json: { 
          success: true, 
          wishlist: @wishlist,
          wishlist_count: @game.wishlists.count,
          in_wishlist: true 
        } }
        format.js   # add_to_wishlist.js.erb
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: @game, alert: "Ошибка: #{@wishlist.errors.full_messages.join(', ')}" }
        format.json { render json: { error: @wishlist.errors.full_messages }, status: :unprocessable_entity }
        format.js   { render js: "alert('Ошибка при добавлении в вишлист');" }
      end
    end
  end
  
  def remove_from_wishlist
    @wishlist = current_user.wishlists.find_by(game: @game)
    
    unless @wishlist
      respond_to do |format|
        format.html { redirect_back fallback_location: @game, alert: 'Игра не найдена в вашем вишлисте' }
        format.json { render json: { error: 'Игра не в вишлисте' }, status: :not_found }
        format.js   { render js: "alert('Игра не в вишлисте');" }
      end
      return
    end
    
    if @wishlist.destroy
      respond_to do |format|
        format.html { redirect_back fallback_location: @game, notice: 'Игра удалена из вишлиста' }
        format.json { render json: { 
          success: true,
          wishlist_count: @game.wishlists.count,
          in_wishlist: false 
        } }
        format.js   # remove_from_wishlist.js.erb
      end
    else
      respond_to do |format|
        format.html { redirect_back fallback_location: @game, alert: 'Ошибка при удаления из вишлиста' }
        format.json { render json: { error: 'Ошибка удаления' }, status: :unprocessable_entity }
        format.js   { render js: "alert('Ошибка при удаления из вишлиста');" }
      end
    end
  end
  
  def toggle_wishlist
    if current_user.wishlists.exists?(game: @game)
      remove_from_wishlist
    else
      add_to_wishlist
    end
  end
  
  def wishlisted_games
    redirect_to wishlists_path unless user_signed_in?
    
    @games = current_user.wishlists.includes(game: [:developers]).map(&:game)
    
    # Группировка по приоритету
    @grouped_games = @games.group_by do |game|
      wishlist_item = current_user.wishlists.find_by(game: game)
      wishlist_item&.priority || 'medium'
    end
  end
  
  private
  
  def set_game
    @game = Game.with_attached_cover
                .includes(:developers, :wishlists, :collections)
                .find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to games_path, alert: 'Игра не найдена'
  end
  
  def game_params
    params.require(:game).permit(
      :title, 
      :description, 
      :release_date, 
      :cover_url, 
      :metacritic_score,
      :cover,  # Для загрузки файла через Active Storage
      developer_ids: []
    )
  end
  
  def set_current_user_for_models
    Thread.current[:current_user] = current_user
  end
  
  def apply_search_filter
    @games = @games.where(
      "title ILIKE :search OR description ILIKE :search", 
      search: "%#{params[:search]}%"
    )
  end
  
  def apply_wishlist_filter
    case params[:filter]
    when 'in_my_wishlist'
      @games = @games.joins(:wishlists).where(wishlists: { user_id: current_user.id })
    when 'not_in_my_wishlist'
      @games = @games.where.not(
        id: current_user.wishlists.select(:game_id)
      ) 
    when 'high_priority'
      @games = @games.joins(:wishlists)
                     .where(wishlists: { 
                       user_id: current_user.id, 
                       priority: 'high'
                     })
    end
  end
  
  def apply_sorting
    case params[:sort]
    when 'title_asc'
      @games = @games.order(title: :asc)
    when 'title_desc'
      @games = @games.order(title: :desc)
    when 'release_desc'
      @games = @games.order(release_date: :desc)
    when 'release_asc'
      @games = @games.order(release_date: :asc)
    when 'rating_desc'
      @games = @games.order(metacritic_score: :desc)
    when 'rating_asc'
      @games = @games.order(metacritic_score: :asc)
    when 'wishlist_desc'
      @games = @games.left_joins(:wishlists)
                     .group('games.id')
                     .order('COUNT(wishlists.id) DESC, games.title ASC')
    when 'popular'
      @games = @games.left_joins(:wishlists, :collections)
                     .group('games.id')
                     .order('(COUNT(DISTINCT wishlists.id) * 2 + COUNT(DISTINCT collections.id)) DESC')
    end
  end
  
  def can_edit_game?
    user_signed_in?
  end
  
  def can_delete_game?
    user_signed_in?
  end
end