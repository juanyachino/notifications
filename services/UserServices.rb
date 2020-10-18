# frozen_string_literal: true

require 'sinatra/base'
require './models/user.rb'
require 'ostruct'

# clase que contiene servicios para verificar cosas con usuarios.
class UserServices < Sinatra::Base
  def self.register(usuario)
    if User.find_by_username(usuario[:username])
      return false
    else
      User.creation(usuario)
    end
  end
  def self.validate_login(user,pw)
    user = User.find_by_username(user)
    return false unless (user && user.password == pw)
    return true
  end
  def self.validate_admin_pw(username,pw)
    return false unless pw == 'admin'
    User.promote_to_admin(User.find_by_username(username))
    return true
  end
end
