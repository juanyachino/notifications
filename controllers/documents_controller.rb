# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/config_file'
require './models/user.rb'
require './models/document.rb'
require './models/documentsUser.rb'
require 'sinatra-websocket'

# clase que contiene las rutas y metodos relacionados al login y registro de usuario.
class DocumentsController < Sinatra::Base
  set :views, settings.root + '/views'
  set :userlist, []

  attr_accessor :users, :documents, :is_admin

  def find_connection(user)
    App.sockets.each { |s| return s[:socket] if s[:user] == user.id }

    nil # Por si el usuario no esta conectado en ese momento
  end

  def get_documents(user)
    if user == 'admin'
      self.is_admin = true
      self.documents = Document.all
      self.users = User.all
      erb :upload, layout: :layoutlogin
    else
      @error = 'Para acceder a documentos debe ser administrador, ' \
               'si desea serlo complete los campos'
      erb :admin, layout: :layoutlogin
    end
  end

  # Endpoints for upload a document
  get '/documents' do
    get_documents(User.find_by_id(session[:user_id]).type)
  end

  post '/documents' do
    filter_docs = Document.all

    doc_date = params[:date] == '' ? filter_docs : Document.first(date: params[:date])
    filter_docs = params[:date] == '' ? filter_docs : filter_docs.select { |d| d.date == doc_date.date }
    self.documents = filter_docs
    erb :upload, layout: :layoutlogin
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
    @filename = params[:file][:filename]
    file = params[:file][:tempfile]
    File.open("./public/#{@filename}", 'wb') do |f|
      f.write(file.read)
    end
    user = User.find_by_id(session[:user_id]).username
    doc = Document.new(name: @filename,
                       date: params['date'],
                       uploader: user,
                       subject: params['subject'])

    if doc.save
      ## extraer esta parte de codigo en un nuevo metodo
      unless params['tagged'].nil?

        ## asignar documento a usuarios etiqutados.
        params['tagged'].each { |n| settings.userlist << (User.find_by_username(n)) }
        settings.userlist.each { |u| u.add_document(doc) }

        sockets_to_be_notified = []

        settings.userlist.each do |tagged_user|
          sockets_to_be_notified << (find_connection(tagged_user)) unless find_connection(tagged_user).nil?
        end

        sockets_to_be_notified.each { |s| s.send('han cargado un nuevo documento!') }

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
