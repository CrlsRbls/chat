class RoomsController < ApplicationController
  include RoomsHelper
  before_action :authenticate_user!
  before_action :set_status

  def index
    @room = Room.new
    @joined_rooms = current_user.joined_rooms
    @rooms = search_rooms

    @users = User.all_except(current_user)
    render 'index'
  end

  def show
    @single_room = Room.find(params[:id])

    @room = Room.new
    @rooms = Room.public_rooms
    @joined_rooms = current_user.joined_rooms

    @message = Message.new
    
    pagy_messages = @single_room.messages.includes(:user).order(created_at: :desc)
    @pagy, messages = pagy(pagy_messages, items: 10)
    @messages = messages.reverse

    @users = User.all_except(current_user)
    render 'index'
  end

  def create
    @room = Room.create(name: params['room']['name'])
    redirect_to @room
  end

  def search
    @rooms = search_rooms
    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: [
          turbo_stream.update('search_results', 
            partial: 'rooms/search_results', 
            locals: {rooms: @rooms})
          ]
      end
    end
  end

  def join
    @room = Room.find(params[:id])
    current_user.joined_rooms
    redirect_to rooms_path
  end

  def leave
    @room = Room.find(params[:id])
    current_user.joined_rooms.delete(@room)
    redirect_to rooms_path
  end

  private

  def set_status
    current_user.update!(status: User.statuses[:online]) if current_user
  end
end