require 'sinatra/base'
require "sinatra/config_file"
require './models/user.rb'
require './models/document.rb'
require './models/documentsUser.rb'
require 'sinatra-websocket'

class App < Sinatra::Base
  register Sinatra::ConfigFile

  config_file 'config/config.yml'

  configure :development, :production do
    enable :logging
    enable :sessions
    set :session_secret, "So0perSeKr3t!"
    set :sessions, true
    set :server, :thin
    set :sockets, []
    set :userlist,[]
    
  end
  
  before do

   @path = request.path_info
    
    if !session[:user_id] && @path != '/login' && @path != '/register'
      redirect '/login'
    elsif session[:user_id]
      @user = User.find(id: session[:user_id])
      is_admin
    end
    
  end

  use Rack::Session::Pool, :expire_after => 2592000
  def is_admin
    user = User.find(id: session[:user_id]).type
    if user == 'admin'
      @isAdmin = true
    end
  end

  get "/" do
    if !request.websocket?
      erb:index, :layout => :layoutlogin
    else
      request.websocket do |ws|
        user = session[:user_id]
        @connection = {user: user, socket: ws}
        ws.onopen do
          settings.sockets << @connection
        end
        ws.onclose do
          warn("websocket closed")
          settings.sockets.delete(ws)
        end
      end
    end
  end

  
 
  # Add new user
  get "/register" do
    erb :register
  end

  post '/register' do
   if User.find(username: params[:username])
    @error = "El Usuario ya existe"
    erb :register
    else
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
    @documents = Document.all
    @user = User.first(id: session[:user_id]).name
    @mail = User.first(id: session[:user_id]).email
    #@user = session[:user_id]
    erb :perfil , :layout => :layoutlogin
  end

  # Endpoints for upload a document
  get '/documents' do
    user = User.find(id: session[:user_id]).type
    if user == 'admin'
      @isAdmin = true
      @documents = Document.all
      @users = User.all
      erb :upload, :layout => :layoutlogin
    else
      @error = "Para acceder a documentos debe ser administrador, si desea serlo complete los campos"
      erb :admin , :layout => :layoutlogin
    end
  end

  post '/documents' do
    user = User.first(username: params[:users])
    filter_docs = Document.all

    doc_date = params[:date] == "" ? filter_docs : Document.first(date: params[:date])
    filter_docs = params[:date] == "" ? filter_docs : filter_docs.select {|d| d.date == doc_date.date }
    @documents = filter_docs
    erb :upload, :layout => :layoutlogin
  end
  get '/userdocs' do
    user = User.find(id: session[:user_id])
    @documents = user.documents ##muestro los documentos de interes del usuario
    erb :userdocs, :layout => :layoutlogin
  end
  get '/publicdocs' do
    @documents = Document.all 
    erb :publicdocs, :layout => :layoutlogin
  end
  get '/showdocument' do
    erb :show_file, :layout => :layoutlogin
  end

  post '/save_documents' do
      @filename = params[:file][:filename]
      file = params[:file][:tempfile]
      File.open("./public/#{@filename}", 'wb') do |f|
        f.write(file.read)
      end
      user = User.find(id: session[:user_id]).username
      doc = Document.new(name: @filename, date: params["date"] , uploader: user, subject: params["subject"])
      
      
      
      #params["tagged"].each { |e| DocumentsUser.new(document_id: doc.id , user_id: (User.first(username: e).id)) }
      #TODO etiquetar antes de informar 
      if doc.save
        logger.info params["tagged"]
        
        params["tagged"].each { |n| settings.userlist <<(User.find(:username => n)) }
        logger.info settings.userlist
        settings.userlist.each { |u| u.add_document(doc) }
        #params["tagged"].each { |e| u= ((User.find(:username => e)).add_document(doc)) }

        #name = params["tagged"].first
        #usertag= User.first(:username => name)
        #usertag.add_document(doc)
        #usertaged.add_document(doc)
        #docuid = Document.find(name:@filename).id
       
       # duck = DocumentsUser.new(document_id: docuid , user_id: usertaged)
       # logger.info doc.id
       # logger.info docuid
       
        #logger.info usertaged
      
        settings.sockets.each{ |s| s[:socket].send("han cargado un nuevo documento!") }
        redirect "/documents"
      
      else
        [500, {}, "Internal Server Error"]
      end
  end

  get '/view/:doc_name' do
      @this_doc = "/" +params[:doc_name]
      erb :view_doc, :layout => :layoutlogin
  end

  get '/remove/:doc_name' do
      docu = Document.where(name: params[:doc_name])
      docu.delete
      if docu.delete
        redirect "/documents"
      else
        [500, {}, "Internal Server Error"]
      end
  end

  get "/admin" do
    erb :admin, :layout => :layoutlogin
  end

  post '/admin' do
    if User.find(username: params[:username])
      codigo = params[:text]
        if codigo == 'admin'
          User.where(username: params[:username]).update(type: 'admin')
          erb :perfil, :layout => :layoutlogin
        else
          @error = "código incorrecto"
          erb :admin , :layout => :layoutlogin
        end
    else
      @error = "Hay algo mal que no está bien"
    end
  end

  ###
  get "/tos" do
  	erb :ToS, :layout => :layoutlogin
  end

  get "/aboutus" do
    erb :aboutus, :layout => :layoutlogin
  end

  get "/contactus" do
    erb :contactus, :layout => :layoutlogin
  end

  # Terminar de implementar
  post "/contactus" do
    "GRACIAS"
  end

  get '/tag' do
    erb :tag, :layout => :layoutlogin
  end

  get "/document_upload" do
    erb :document_upload, :layout => :layoutlogin
  end

end
