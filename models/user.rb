# frozen_string_literal: true

# Clase que representa la entidad User
class User < Sequel::Model
  plugin :validation_helpers
  def validate
    super
    validates_presence %i[name email username password]
    validates_unique [:username]
  end

  def self.find_by_id(id)
    find(id: id)
  end

  def self.find_by_username(username)
    find(username: username)
  end
  many_to_many :documents
  many_to_many :init
  set_primary_key :id
end
