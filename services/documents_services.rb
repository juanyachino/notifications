# frozen_string_literal: true

require 'sinatra/base'
require './models/document.rb'
require './models/user.rb'
require 'ostruct'

# clase que contiene servicios para verificar cosas con usuarios.
class DocumentServices < Sinatra::Base
  set :userlist, []

  def self.create(documento)
    Document.creation(documento)
  end

  def self.tagged_doc(doc, tagged, settings)
    unless tagged.nil?
      tagged.each { |n| settings.userlist << (User.find_by_username(n)) }
      settings.userlist.each { |u| u.add_document(doc) }
    end
    userlist
  end
end
