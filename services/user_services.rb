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
    return false unless pass == 'admin'

    User.promote_to_admin(User.find_by_username(username))
    true
  end

  def self.admin?(actual_user)
    User.find_by_id(actual_user).type == 'admin'
  end
end
