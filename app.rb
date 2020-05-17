require 'sinatra/base'
require "sinatra/config_file"
require './models/user.rb'

class App < Sinatra::Base
  register Sinatra::ConfigFile

  config_file 'config/config.yml'

  configure :development, :production do
    enable :logging
    enable :sessions
    set :session_secret, "So0perSeKr3t!"
    set :sessions, true
  end

 before do 
    @path = request.path_info
    if !session[:user_id] && @path != '/login' && @path != '/register'
      redirect '/login'
    elsif session[:user_id]
      @user = User.find(id: session[:user_id])
    end
  end

  use Rack::Session::Pool, :expire_after => 2592000

  get "/" do
    logger.info "Session inicilized"
    logger.info session["session_id"]
    logger.info session.inspect
    logger.info session[:user_id]
    logger.info "--------------"
    logger.info ""
  	erb :index, :layout => :layoutlogin
  end

  # Add new user
  get "/register" do
    erb :register
  end

  post '/register' do
   request.body.rewind
   hash = Rack::Utils.parse_nested_query(request.body.read)
   params = JSON.parse hash.to_json
   user = User.new(name: params["name"], email: params["email"], username: params["username"], password: params["psw"])
   if user.save
    redirect "/login"
   else
    [500, {}, "Internal Server Error"]
   end
  end

  # Login Endpoints
  get "/login" do
    erb :login
  end

  post '/login' do
    users = User.find(username: params[:username])
    if users && users.password == params[:password]
      session[:user_id] = users.id
      redirect "/"
    else
      @error = "Usuario o contraseña incorrecta"
      erb :login
    end
  end

  get '/logout' do
    session.clear
    # response.set_cookie("user_id", value: "", expires: Time.now - 100 )
    redirect '/'
  end

  # Endpoints for handles profile
  get "/profile" do
    @user = User.find(id: session[:user_id])
    @nombre = @user.name
    erb :perfil , :layout => :layoutlogin
  end

  # Endpoints for upload a document
  get '/documents' do
    erb :upload, :layout => :layoutlogin
  end

  get '/showdocument' do
    erb :show_file
  end

  post '/save_documents' do
      @filename = params[:file][:filename]
      file = params[:file][:tempfile]
      File.open("./public/#{@filename}", 'wb') do |f|
        f.write(file.read)
      end
      erb :tag
  end

  ###
  get "/tos" do
  	erb :ToS
  end

  get "/aboutus" do
    erb :aboutus
  end

  get "/contactus" do
    erb :contactus
  end

  post '/tag' do
    erb :tag
  end

  get "/document_upload" do
    erb :document_upload
  end

end
