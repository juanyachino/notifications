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

  def self.bring_all
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
    if !user.valid?
        raise ArgumentError.new("Por favor debe completar todos los campos")
    else
        user if user.save
    end
  end

  many_to_many :documents
  many_to_many :init
  set_primary_key :id
end

