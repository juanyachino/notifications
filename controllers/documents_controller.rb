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
    DocumentServices.create_file(params[:file][:filename] , params[:file][:tempfile])
    user = User.find_by_id(session[:user_id]).username
    doc = Document.new(name: params[:file][:filename],
                       date: params['date'],
                       uploader: user,
                       subject: params['subject'])
    if doc.save
      UserServices.send_notifications(DocumentServices.tagged_doc(doc, params['tagged']))
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
