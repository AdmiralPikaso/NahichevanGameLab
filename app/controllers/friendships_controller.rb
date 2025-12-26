class FriendshipsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @friends = current_user.friends.includes(:profile)
    @friends_count = @friends.count
    @pending_requests = current_user.pending_sent_requests.count
    @incoming_requests = current_user.pending_received_requests.count
  
    # Добавляем пагинацию только если гем установлен
    if defined?(Kaminari)
      @friends = @friends.page(params[:page]).per(20)
    elsif defined?(WillPaginate)
      @friends = @friends.paginate(page: params[:page], per_page: 20)
    end
  end

  def pending
    # Вместо использования методов модели, делаем прямые запросы
    @incoming_requests = Friendship.where(friend_id: current_user.id, status: 'pending').includes(:user)
    @outgoing_requests = Friendship.where(user_id: current_user.id, status: 'pending').includes(:friend)
  end
  
  def suggestions
    # Простой запрос без фильтрации по друзьям
    @suggestions = User.where.not(id: current_user.id)
                     .includes(:profile)
                     .order(created_at: :desc)
                     .limit(20)
  
    # Если есть поисковый запрос, просто фильтруем по email
    if params[:search].present?
      search = params[:search].to_s.downcase.strip
      @suggestions = @suggestions.where("LOWER(email) LIKE ?", "%#{search}%")
    end
  
    # Возвращаем только пользователей, с которыми еще нет дружбы
    @suggestions = @suggestions.reject do |user|
      Friendship.where(
        "(user_id = ? AND friend_id = ?) OR (user_id = ? AND friend_id = ?)",
        current_user.id, user.id, user.id, current_user.id
      ).exists?
    end
  
    # Преобразуем обратно в массив для работы в шаблоне
    @suggestions = Kaminari.paginate_array(@suggestions).page(params[:page]).per(12) if defined?(Kaminari)
  end
  
  def create
    friend = User.find_by(id: params[:friend_id])
    
    unless friend
      redirect_back fallback_location: profiles_path, alert: "Пользователь не найден"
      return
    end
    
    # Проверяем, не отправили ли уже заявку
    if current_user.pending_request_to?(friend)
      redirect_back fallback_location: profiles_path, alert: "Вы уже отправили заявку этому пользователю"
      return
    end
    
    # Проверяем, не друзья ли уже
    if current_user.friends_with?(friend)
      redirect_back fallback_location: profiles_path, alert: "Вы уже друзья с этим пользователем"
      return
    end
    
    # Проверяем, не отправил ли уже заявку этот пользователь
    if current_user.pending_request_from?(friend)
      # Автоматически принимаем заявку
      friendship = Friendship.find_by(user_id: friend.id, friend_id: current_user.id, status: 'pending')
      if friendship&.update(status: 'accepted')
        redirect_back fallback_location: profiles_path, notice: "Вы теперь друзья с #{friend.email}!"
      else
        redirect_back fallback_location: profiles_path, alert: "Ошибка при принятии заявки"
      end
      return
    end
    
    # Создаем новую заявку
    friendship = current_user.friendships.new(friend: friend, status: 'pending')
    
    if friendship.save
      redirect_back fallback_location: profiles_path, notice: "Заявка в друзья отправлена пользователю #{friend.email}"
    else
      redirect_back fallback_location: profiles_path, alert: "Ошибка при отправке заявки: #{friendship.errors.full_messages.join(', ')}"
    end
  end
  
  def accept
    friendship = current_user.inverse_friendships.find_by(id: params[:id], status: 'pending')
  
    unless friendship
      redirect_to pending_friendships_path, alert: "Заявка не найдена"
      return
    end
  
    if friendship.update(status: 'accepted')
      redirect_to friendships_path, notice: "Заявка принята!"
    else
      redirect_to pending_friendships_path, alert: "Ошибка при принятии заявки"
    end
  end

  def reject
    friendship = current_user.inverse_friendships.find_by(id: params[:id], status: 'pending')
  
    unless friendship
      redirect_to pending_friendships_path, alert: "Заявка не найдена"
      return
    end
  
    if friendship.update(status: 'rejected')
      redirect_to pending_friendships_path, notice: "Заявка отклонена"
    else
      redirect_to pending_friendships_path, alert: "Ошибка при отклонении заявки"
    end
  end
  
  def destroy
    friendship = Friendship.find_by(id: params[:id])
    
    unless friendship
      redirect_back fallback_location: friendships_path, alert: "Запись о дружбе не найдена"
      return
    end
    
    # Проверяем, что текущий пользователь является участником дружбы
    unless friendship.user_id == current_user.id || friendship.friend_id == current_user.id
      redirect_to friendships_path, alert: "У вас нет прав для этого действия"
      return
    end
    
    if friendship.destroy
      redirect_back fallback_location: friendships_path, notice: "Дружба удалена"
    else
      redirect_back fallback_location: friendships_path, alert: "Ошибка при удалении дружбы"
    end
  end
  
  private
  
  def friendship_params
    params.require(:friendship).permit(:friend_id, :status)
  end
end