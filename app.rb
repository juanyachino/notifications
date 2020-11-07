# frozen_string_literal: true

require 'sinatra/base'
require 'sinatra/config_file'
require 'sinatra-websocket'
require './controllers/users_controller.rb'
require './services/user_services.rb'
require './controllers/documents_controller.rb'

# clase que contiene las rutas y metodos de la aplicacion.
class App < Sinatra::Base
  register Sinatra::ConfigFile
  use UsersController
  use DocumentsController
  use UserServices
  config_file 'config/config.yml'

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
        ws.onopen do
          settings.sockets << UserServices.handle_websocket(ws, session[:user_id])
        end
        ws.onclose do
          warn('websocket closed')
          settings.sockets.delete(ws)
        end
      end
    end
  end
end
