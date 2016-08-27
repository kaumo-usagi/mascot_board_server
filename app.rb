require 'bundler'
Bundler.require
require 'sinatra/reloader' if development?
require './models'
require './api'
require 'json'
require 'securerandom'
unless development? 
  set :environment, :production
  set :port, 80
end
use Rack::Session::Cookie
set :server, 'thin'

get '/' do
  @boards = Board.all
  erb :index
end

get '/sign_up' do
  @form_action = '/sign_up'
  @form_title = "SignupPage"
  erb :sign
end

post '/sign_up' do
  session[:user_token] = SecureRandom.uuid
  User.create(mail: params[:mail], token: session[:user_token], password: params[:password], password_confirmation: params[:password])
  redirect '/admin'
end

get '/sign_in' do
  @form_action = '/sign_in'
  @form_title = "SigninPage"
  erb :sign
end

post '/sign_in' do
  user = User.find_by(mail: params[:mail])
  if user && user.authenticate(params[:password])
    session[:user_token] = user.token
    redirect '/admin'
  else
    redirect '/sign_up'
  end
end

get '/admin' do
  if User.find_by(token: session[:user_token]).administrator?
    @stamps = Stamp.all
    erb :admin_page
  else
    redirect '/sign_in'
  end
end

post '/stamp_uploader' do
  Stamp.create(data: params[:image])
  redirect '/admin'
end

post '/boards' do
  name = SecureRandom.uuid
  Board.create(name: name, screen_name: params[:board_name])
  redirect "/boards/#{name}"
end

get '/boards/:id' do
  @board = Board.find_by(name: params[:id])

  user_attrs = { id: 1, name: "izumin" }

  if @board.nil?
    redirect "/"
  elsif !request.websocket?
    erb :room
  else
    redis = EM::Hiredis.connect
    channel = "boards::#{@board.id}"

    request.websocket do |ws|
      ws.onopen do
        redis.pubsub.subscribe(channel) do |msg|
          ws.send({ user: user_attrs, body: msg }.to_json)
        end
      end

      ws.onmessage do |msg|
        EM.next_tick do
          redis.publish(channel, msg).errback { |e| p e }
        end
      end

      ws.onclose do
        warn("close websocket connection")
        redis.pubsub.unsubscribe(channel)
      end
    end
  end
end
