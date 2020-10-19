# frozen_string_literal: true

require 'sinatra/base'
require './models/document.rb'
require 'ostruct'

# clase que contiene servicios para verificar cosas con usuarios.
class DocumentServices < Sinatra::Base
  def self.load_all (actual_user)
     if UserServices.admin?(actual_user)
        hash = { documents: Document.bring_all,
                users: User.bring_all,
                error: nil }
     else
        hash = { error:'Para acceder a documentos debe ser administrador, ' \
               'si desea serlo complete los campos'
               }
     end
     return OpenStruct.new(hash)
  end
end
