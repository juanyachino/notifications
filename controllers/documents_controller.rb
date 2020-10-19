# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/config_file'
require './models/user.rb'
require './models/document.rb'
require './models/documentsUser.rb'
require './services/user_services.rb'
require './services/document_services.rb'

require 'sinatra-websocket'

# clase que contiene las rutas y metodos relacionados al login y registro de usuario.
class DocumentsController < Sinatra::Base
  set :views, settings.root + '/views'
  set :userlist, []

  attr_accessor :users, :documents, :is_admin

  # Endpoints for upload a document
  get '/documents' do
    hash = DocumentServices.load_all(session[:user_id])
    if hash[:error] == nil
      @is_admin = true
      @documents = hash[:documents]
      @users = hash[:users]
      erb :upload, layout: :layoutlogin
    else
      @error = hash[:error]
      erb :admin, layout: :layoutlogin
    end
  end
 
  get '/userdocs' do
    self.documents = User.find_by_id(session[:user_id]).documents
    erb :userdocs, layout: :layoutlogin
  end
  get '/publicdocs' do
    self.documents = Document.all
    erb :publicdocs, layout: :layoutlogin
  end
  get '/showdocument' do
    erb :show_file, layout: :layoutlogin
  end

  post '/save_documents' do
    hash = { filename: params[:file][:filename],
             file: params[:file][:tempfile],
             date: params['date'],
             uploader: User.find_by_id(session[:user_id]).username,
             subject: params['subject'] }
    
    doc = DocumentServices.create_file(OpenStruct.new(hash))
    if doc != nil
      UserServices.send_notifications(DocumentServices.tag_users(doc, params['tagged'])) 
      redirect '/documents'
    else
      [500, {}, 'Internal Server Error']
    end
  end

  get '/view/:doc_name' do
    @this_doc = '/' + params[:doc_name]
    erb :view_doc, layout: false
  end

  get '/remove/:doc_id' do
    docu = Document.where(id: params[:doc_id])
    docu.delete
    if docu.delete
      redirect '/documents'
    else
      [500, {}, 'Internal Server Error']
    end
  end
end
