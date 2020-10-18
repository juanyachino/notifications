# frozen_string_literal: true

require 'sinatra/base'
require './models/user.rb'
require './models/document.rb'
require './models/documentsUser.rb'
require './services/UserServices.rb'
require 'ostruct'

# clase que contiene las rutas relacionadas al login y registro de usuario.
class UsersController < Sinatra::Base
  set :views, settings.root + '/views'
  
  # Add new user
  get '/register' do
    erb :register
  end

  post '/register' do
    request.body.rewind
    hash = Rack::Utils.parse_nested_query(request.body.read)
    params = JSON.parse hash.to_json
    hash = { :name => params['name'], 
             :email => params['email'],
             :username => params['username'],
             :password => params['psw'] }
    redirect '/login' unless !UserServices.register(OpenStruct.new(hash))
    #redirect '/login' unless !User.register(OpenStruct.new(hash))
    @error = 'El usuario ya existe'
    erb :register
  end
  # Login Endpoints
  get '/login' do
    erb :login
  end

  post '/login' do
    if UserServices.validate_login(params[:username], params[:password]) 
      session[:user_id] = User.find_by_username(params[:username]).id
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
  get '/admin' do
    erb :admin, layout: :layoutlogin
  end

  post '/admin' do
    if UserServices.validate_admin_pw(params[:text])
    ##if params[:text] == 'admin'
       User.promote_to_admin(User.find_by_username(params[:username]))
       erb :perfil, layout: :layoutlogin
    else 
      @error = 'código incorrecto'
      erb :admin, layout: :layoutlogin
    end
  end
end
