# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra-websocket'
require './controllers/users_controller.rb'
require './services/UserServices.rb'
require './controllers/documents_controller.rb'

# clase que contiene las rutas y metodos de la aplicacion.
class App < Sinatra::Base
  register Sinatra::ConfigFile
  use UsersController
  use DocumentsController
  use UserServices
  config_file 'config/config.yml'
  set :views, settings.root + '/controllers/views'

  configure :development, :production do
    enable :logging
    enable :sessions
    set :session_secret, 'So0perSeKr3t!'
    set :sessions, true
    set :server, :thin
    set :sockets, []
  end

  attr_accessor :documents, :user, :mail

  before do
    @path = request.path_info

    if !session[:user_id] && @path != '/login' && @path != '/register'
      redirect '/login'
    elsif session[:user_id]
      @is_admin = UserServices.admin?(session[:user_id]) unless User.find_by_id(session[:user_id]).nil?
    end
  end

  use Rack::Session::Pool, expire_after: 2_592_000
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
    self.documents = Document.all
    self.user = User.first(id: session[:user_id]).name
    self.mail = User.first(id: session[:user_id]).email

    erb :perfil, layout: :layoutlogin
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
