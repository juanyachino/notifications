# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/config_file'
require './models/user.rb'
require './models/document.rb'
require './models/documents_user.rb'
require './services/user_services.rb'
require './services/document_services.rb'

require 'sinatra-websocket'

# clase que contiene las rutas y metodos relacionados al login y registro de usuario.
class DocumentsController < Sinatra::Base
  set :views, settings.root + '/../views'
  set :userlist, []

  attr_accessor :users, :documents, :is_admin

  get '/documents' do
    begin
      hash = DocumentServices.load_all(session[:user_id])
    rescue ArgumentError => e
      return erb :admin, layout: :layoutlogin, locals: { errorMessage: e.message }
    end
    if hash[:error].nil?
      @is_admin = true
      @documents = hash[:documents]
      @users = hash[:users]
      erb :upload, layout: :layoutlogin
    end
  end

  get '/userdocs' do
    self.documents = User.find_by_id(session[:user_id]).documents
    @is_admin = if UserServices.admin?(session[:user_id])
                  true
                else
                  false
                end
    erb :userdocs, layout: :layoutlogin
  end

  get '/publicdocs' do
    self.documents = Document.all
    @is_admin = if UserServices.admin?(session[:user_id])
                  true
                else
                  false
                end
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
    begin
    doc = DocumentServices.create_file(OpenStruct.new(hash))
    rescue ArgumentError => e
      return erb :error, layout: :layoutlogin, locals: { errorMessage: e.message }
  end
    if !doc.nil?
      begin
          UserServices.send_notifications(DocumentServices.tag_users(doc, params['tagged']))
      rescue ArgumentError => e
        return erb :error, layout: :layoutlogin, locals: { errorMessage: e.message }
        end
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
