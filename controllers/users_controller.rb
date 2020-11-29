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
  rescue ArgumentError => e
    return erb :register, locals: { errorMessage: e.message }
  end
  # Login Endpoints
  get '/login' do
    erb :login
  end

  post '/login' do
    if UserServices.validate_login(params[:username], params[:password])
      session[:user_id] = User.find_by_username(params[:username]).id
      redirect '/'
    end
  rescue ArgumentError => e
    erb :login, locals: { errorMessage: e.message }
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
    erb :perfil, layout: :layoutlogin if UserServices.validate_admin_pw(params[:username], params[:text])
  rescue ArgumentError => e
    erb :admin, layout: :layoutlogin, locals: { errorMessage: e.message }
  end

  get '/profile' do
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
