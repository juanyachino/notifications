# frozen_string_literal: true# frozen_string_literal: true

require 'sinatra/base'
require './models/user.rb'
require './models/document.rb'
require './models/documentsUser.rb'

# clase que contiene las rutas relacionadas al login y registro de usuario.
class UsersController < Sinatra::Base
  set :views, settings.root + '/views'
  # Add new user
  get '/register' do
    erb :register
  end

  post '/register' do
    if User.find_by_username(params[:username])
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
    user = User.find_by_username(params[:username])
    if user && user.password == params[:password]
      session[:user_id] = user.id
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
    if User.promote_user_to_admin(User.find_by_username(params[:username]), params[:text])
      erb :perfil, layout: :layoutlogin
    else 
      @error = 'código incorrecto'
      erb :admin, layout: :layoutlogin
    end
  end
end
