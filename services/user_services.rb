# frozen_string_literal: true

require 'sinatra/base'
require './models/user.rb'
require 'ostruct'

# clase que contiene servicios para verificar cosas con usuarios.
class UserServices < Sinatra::Base
  def self.register(usuario)
    raise ArgumentError, 'El usuario registrado ya existe' if User.find_by_username(usuario[:username])
    raise ArgumentError, 'Las contraseñas no coinciden' if usuario[:password] != usuario[:psw]

    User.creation(usuario)
  end

  def self.validate_login(user, pass)
    raise ArgumentError, 'Complete todos los datos' if user.nil? || pass.nil?

    user = User.find_by_username(user)
    raise ArgumentError, 'Datos incorrectos' if user.nil? || user.password != pass

    true
  end

  def self.validate_admin_pw(username, pass)
    raise ArgumentError, 'Complete todos los datos' if username.nil? || pass.nil?

    user = User.find_by_username(username)
    raise ArgumentError, 'Codigo incorrecto' if pass != 'admin' || user.nil?

    User.promote_to_admin(user)
    true
  end

  def self.admin?(actual_user)
    User.find_by_id(actual_user).type == 'admin'
  end

  def self.find_connection(user)
    App.sockets.each { |s| return s[:socket] if s[:user] == user.id }

    nil # Por si el usuario no esta conectado en ese momento
  end

  def self.send_notifications(userlist)
    sockets_to_be_notified = []
    userlist.each do |tagged_user|
      sockets_to_be_notified << (find_connection(tagged_user)) unless find_connection(tagged_user).nil?
    end
    sockets_to_be_notified.each { |s| s.send('han cargado un nuevo documento!') }
  end
end
