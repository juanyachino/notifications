# frozen_string_literal: true

require 'sinatra/base'
require './models/user.rb'
require './services/user_services.rb'
require 'ostruct'

# clase que contiene las rutas relacionadas al login y registro de usuario.
class UsersController < Sinatra::Base
  set :views, settings.root + '/../views'

  # Add new user
  get '/register' do
    erb :register
  end

  post '/register' do
    request.body.rewind
    hash = Rack::Utils.parse_nested_query(request.body.read)
    params = JSON.parse hash.to_json
    hash = { name: params['name'],
             email: params['email'],
             username: params['username'],
             password: params['psw'] }
    redirect '/login' if UserServices.register(OpenStruct.new(hash))
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
    if UserServices.validate_admin_pw(params[:username], params[:text])
      erb :perfil, layout: :layoutlogin
    else
      @error = 'código incorrecto o el usuario no existe'
      erb :admin, layout: :layoutlogin
    end
  end
  get '/profile' do
    info = UserServices.load_profile_info(session[:user_id])
    @documents = info[:documents]
    @user = info[:user]
    @mail = info[:mail]
    erb :perfil, layout: :layoutlogin
  end
  get '/tos' do
    erb :ToS, layout: :layoutlogin
  end
  get '/aboutus' do
    erb :aboutus, layout: :layoutlogin
  end
  get '/contactus' do
    erb :contactus, layout: :layoutlogin
  end
  post '/contactus' do
    'GRACIAS'
  end
end
