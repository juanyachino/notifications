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
    return false unless pass == 'admin' && user != nil
    User.promote_to_admin(user)
    true
  end

  def self.admin?(actual_user)
    User.find_by_id(actual_user).type == 'admin'
  end

  def self.socket_notified(sockets_to_be_notified)
    sockets_to_be_notified.each { |s| s.send('han cargado un nuevo documento!') }
  end

end
