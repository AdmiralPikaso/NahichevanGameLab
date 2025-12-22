class FriendshipsController < ApplicationController
  before_action :authenticate_user!
  
  def index
    @friends = current_user.accepted_friends.includes(:profile)
    @friends_count = @friends.count
    @pending_incoming_count = current_user.requested_friends.count
    @pending_outgoing_count = current_user.pending_friends.count
  end
  
  def pending
    @incoming_requests = current_user.requested_friends.includes(:profile)
    @outgoing_requests = current_user.pending_friends.includes(:profile)
  end
  
  def create
    friend = User.find_by(id: params[:friend_id])
    
    unless friend
      redirect_back fallback_location: users_path, alert: "Пользователь не найден"
      return
    end
    
    # Проверяем, не отправили ли уже заявку
    if current_user.pending_request_to?(friend)
      redirect_back fallback_location: users_path, alert: "Вы уже отправили заявку этому пользователю"
      return
    end
    
    # Проверяем, не друзья ли уже
    if current_user.friend_with?(friend)
      redirect_back fallback_location: users_path, alert: "Вы уже друзья с этим пользователем"
      return
    end
    
    # Проверяем, не отправил ли уже заявку этот пользователь
    if current_user.pending_request_from?(friend)
      friendship = Friendship.find_by(user_id: friend.id, friend_id: current_user.id, status: 'pending')
      if friendship&.update(status: 'accepted')
        redirect_back fallback_location: users_path, notice: "Вы теперь друзья с #{friend.email}!"
      else
        redirect_back fallback_location: users_path, alert: "Ошибка при принятии заявки"
      end
      return
    end
    
    # Создаем новую заявку
    friendship = current_user.friendships.new(friend: friend, status: 'pending')
    
    if friendship.save
      redirect_back fallback_location: users_path, notice: "Заявка в друзья отправлена пользователю #{friend.email}"
    else
      redirect_back fallback_location: users_path, alert: "Ошибка при отправке заявки"
    end
  end
  
  def update
    friendship = Friendship.find_by(id: params[:id])
    
    unless friendship
      redirect_to friendships_path, alert: "Заявка не найдена"
      return
    end
    
    if friendship.friend_id == current_user.id && friendship.pending?
      if friendship.update(status: 'accepted')
        redirect_to friendships_path, notice: "Заявка в друзья принята!"
      else
        redirect_to pending_friendships_path, alert: "Ошибка при принятии заявки"
      end
    else
      redirect_to friendships_path, alert: "Невозможно выполнить это действие"
    end
  end
  
  def destroy
    friendship = Friendship.find_by(id: params[:id])
    
    unless friendship
      redirect_back fallback_location: friendships_path, alert: "Запись о дружбе не найдена"
      return
    end
    
    if friendship.user_id == current_user.id || friendship.friend_id == current_user.id
      friend = friendship.user_id == current_user.id ? friendship.friend : friendship.user
      
      if friendship.destroy
        redirect_back fallback_location: friendships_path, notice: "Дружба с #{friend.email} удалена"
      else
        redirect_back fallback_location: friendships_path, alert: "Ошибка при удалении дружбы"
      end
    else
      redirect_to friendships_path, alert: "У вас нет прав для этого действия"
    end
  end
  
  private
  
  def friendship_params
    params.require(:friendship).permit(:friend_id, :status)
  end
end