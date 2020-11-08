# frozen_string_literal: true

require 'sinatra/base'
require './models/document.rb'
require './models/user.rb'
require './models/documents_user.rb'
require 'ostruct'

# clase que contiene servicios para verificar cosas con usuarios.
class DocumentServices < Sinatra::Base
  set :userlist, []

  def self.create(documento)
    Document.creation(documento)
  end

  def self.tag_users(doc, tagged)
    userlist = []
    raise ArgumentError, 'No se registra archivo, vuelva a intentarlo' if doc.nil?

    unless tagged.nil?
      tagged.each { |n| userlist << (User.find_by_username(n)) }
      userlist.each { |u| u.add_document(doc) }
    end
    userlist
  end

  def self.load_all(actual_user)
    hash = if UserServices.admin?(actual_user)
             { documents: Document.bring_all,
               users: User.bring_all,
               error: nil }
           else
             raise ArgumentError, 'Para acceder a documentos debe ser administrador, si desea serlo complete los campos'
           end
    OpenStruct.new(hash)
  end

  def self.create_file(hash)
    @filename = hash[:filename]
    @file = hash[:file]
    File.open("./public/#{@filename}", 'wb') do |f|
      f.write(@file.read)
    end
    Document.create(hash)
  end
end
