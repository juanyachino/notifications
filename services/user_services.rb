# frozen_string_literal: true

require 'sinatra/base'
require './models/user.rb'
require 'ostruct'

# clase que contiene servicios para verificar cosas con usuarios.
class UserServices < Sinatra::Base
  def self.register(usuario)
    if User.find_by_username(usuario[:username])
      false
    else
      User.creation(usuario)
    end
  end

  def self.validate_login(user, pass)
    user = User.find_by_username(user)
    return false unless user && user.password == pass

    true
  end

  def self.validate_admin_pw(username, pass)
    user = User.find_by_username(username)
    return false unless pass == 'admin' && !user.nil?

    User.promote_to_admin(user)
    true
  end

  def self.admin?(actual_user)
    User.find_by_id(actual_user).type == 'admin'
  end

  def self.find_connection(user)
    App.sockets.each { |s| return s[:socket] if s[:user] == user.id }

    nil
  end

  def self.send_notifications(userlist)
    sockets_to_be_notified = []
    userlist.each do |tagged_user|
      sockets_to_be_notified << (find_connection(tagged_user)) unless find_connection(tagged_user).nil?
    end
    sockets_to_be_notified.each { |s| s.send('han cargado un nuevo documento!') }
  end

  def self.load_profile_info(session_id)
    hash = { documents: Document.all,
             user: User.first(id: session_id).name,
             mail: User.first(id: session_id).email,
             }
    info = OpenStruct.new(hash)
  end

  def self.handle_websocket(websocket, user)
    connection = { user: user, socket: websocket }
    websocket.onopen do
      warn('websocket opened')
      connection
    end 
  end

end
