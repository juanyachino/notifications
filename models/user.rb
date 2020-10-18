# frozen_string_literal: true
require 'ostruct'
# Clase que representa la entidad User
class User < Sequel::Model
  plugin :validation_helpers
  def validate
    super
    validates_presence %i[name email username password]
    validates_unique [:username]
  end
  def self.get_all
    User.all
  end
  def self.find_by_id(id)
    find(id: id)
  end

  def self.find_by_username(username)
    find(username: username)
  end
  def self.promote_to_admin(user)
      user.update(type: 'admin')
  end
  def self.creation(usuario)
      user = User.new(name: usuario[:name],
                      email: usuario[:email],
                      username: usuario[:username],
                      password: usuario[:password])
      return true unless !user.save
      [500, {}, 'Internal Server Error']
  end
  def self.register(usuario)
    if User.find_by_username(usuario[:username])
      @error = 'El Usuario ya existe'
      erb :register
    else
      creation(usuario)
    end
  end
  def self.find_connection(user)
    App.sockets.each { |s| return s[:socket] if s[:user] == user.id }

    nil # Por si el usuario no esta conectado en ese momento
  end  
  many_to_many :documents
  many_to_many :init
  set_primary_key :id
end
