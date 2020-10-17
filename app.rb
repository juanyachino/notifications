# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/config_file'
require './models/user.rb'
require './models/document.rb'
require './models/documentsUser.rb'
require 'sinatra-websocket'

# clase que contiene las rutas y metodos relacionados al login y registro de usuario.
class LoginScreen < Sinatra::Base
  # Add new user
  get '/register' do
    erb :register
  end

  post '/register' do
    if User.find(username: params[:username])
      @error = 'El Usuario ya existe'
      erb :register
    else
      request.body.rewind
      hash = Rack::Utils.parse_nested_query(request.body.read)
      params = JSON.parse hash.to_json
      user = User.new(name: params['name'],
                      email: params['email'],
                      username: params['username'],
                      password: params['psw'])
      if user.save
        redirect '/login'
      else
        [500, {}, 'Internal Server Error']
      end
    end
  end
  # Login Endpoints
  get '/login' do
    erb :login
  end

  post '/login' do
    users = User.find(username: params[:username])
    if users && users.password == params[:password]
      session[:user_id] = users.id
      redirect '/'
    else
      @error = 'Usuario o contraseña incorrecta'
      erb :login
    end
  end

  get '/logout' do
    session.clear
    # response.set_cookie("user_id", value: "", expires: Time.now - 100 )
    redirect '/'
  end
end

# clase que contiene las rutas y metodos relacionados al login y registro de usuario.
class Documents < Sinatra::Base
  set :userlist, []

  def find_connection(user)
    App.sockets.each { |s| return s[:socket] if s[:user] == user.id }

    nil # Por si el usuario no esta conectado en ese momento
  end

  def get_documents(user)
    if user == 'admin'
      @is_admin = true
      @documents = Document.all
      @users = User.all
      erb :upload, layout: :layoutlogin
    else
      @error = 'Para acceder a documentos debe ser administrador, ' \
               'si desea serlo complete los campos'
      erb :admin, layout: :layoutlogin
    end
  end

  # Endpoints for upload a document
  get '/documents' do
    get_documents(User.find(id: session[:user_id]).type)
  end

  post '/documents' do
    filter_docs = Document.all

    doc_date = params[:date] == '' ? filter_docs : Document.first(date: params[:date])
    filter_docs = params[:date] == '' ? filter_docs : filter_docs.select { |d| d.date == doc_date.date }
    @documents = filter_docs
    erb :upload, layout: :layoutlogin
  end
  get '/userdocs' do
    user = User.find(id: session[:user_id])
    @documents = user.documents # #muestro los documentos de interes del usuario
    erb :userdocs, layout: :layoutlogin
  end
  get '/publicdocs' do
    @documents = Document.all
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
    user = User.find(id: session[:user_id]).username
    doc = Document.new(name: @filename,
                       date: params['date'],
                       uploader: user,
                       subject: params['subject'])

    if doc.save

      unless params['tagged'].nil?

        ## asignar documento a usuarios etiqutados.
        params['tagged'].each { |n| settings.userlist << (User.find(username: n)) }
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

# clase que contiene las rutas y metodos de la aplicacion.
class App < Sinatra::Base
  register Sinatra::ConfigFile
  use LoginScreen
  use Documents

  config_file 'config/config.yml'

  configure :development, :production do
    enable :logging
    enable :sessions
    set :session_secret, 'So0perSeKr3t!'
    set :sessions, true
    set :server, :thin
    set :sockets, []
  end

  before do
    @path = request.path_info

    if !session[:user_id] && @path != '/login' && @path != '/register'
      redirect '/login'
    elsif session[:user_id]
      @user = User.find(id: session[:user_id])
      admin? unless @user.nil?
    end
  end

  use Rack::Session::Pool, expire_after: 2_592_000
  def admin?
    user = User.find(id: session[:user_id]).type
    @is_admin = true if user == 'admin'
  end
  get '/' do
    if !request.websocket?
      erb :index, layout: :layoutlogin
    else
      request.websocket do |ws|
        user = session[:user_id]
        @connection = { user: user, socket: ws }
        ws.onopen do
          settings.sockets << @connection
        end
        ws.onclose do
          warn('websocket closed')
          settings.sockets.delete(ws)
        end
      end
    end
  end

  # Endpoints for handles profile
  get '/profile' do
    @documents = Document.all
    @user = User.first(id: session[:user_id]).name
    @mail = User.first(id: session[:user_id]).email

    erb :perfil, layout: :layoutlogin
  end

  get '/admin' do
    erb :admin, layout: :layoutlogin
  end

  post '/admin' do
    if User.find(username: params[:username])
      codigo = params[:text]
      if codigo == 'admin'
        User.where(username: params[:username]).update(type: 'admin')
        erb :perfil, layout: :layoutlogin
      else
        @error = 'código incorrecto'
        erb :admin, layout: :layoutlogin
      end
    else
      @error = 'Hay algo que no está bien'
    end
  end

  ###
  get '/tos' do
    erb :ToS, layout: :layoutlogin
  end

  get '/aboutus' do
    erb :aboutus, layout: :layoutlogin
  end

  get '/contactus' do
    erb :contactus, layout: :layoutlogin
  end

  # Terminar de implementar
  post '/contactus' do
    'GRACIAS'
  end

  get '/tag' do
    erb :tag, layout: :layoutlogin
  end

  get '/document_upload' do
    erb :document_upload, layout: :layoutlogin
  end
end
