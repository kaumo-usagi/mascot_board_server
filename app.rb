require 'bundler'
Bundler.require
require 'sinatra/reloader' if development?
require './models'
require 'json'
require 'securerandom'

use Rack::Session::Cookie
set :server, 'thin'

get '/' do
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
  redirect '/admin_page'
end

get '/sign_in' do
  @form_action = '/sign_in'
  @form_title = "SigninPage"
  erb :sign
end

post '/sign_in' do
  user = User.find_by_mail(mail: params[:mail])
  if user && user.authenticate(params[:password])
    session[:user_token] = user.token
    redirect '/admin_page'
  else
    redirect '/sign_up'
  end
end

get '/admin_page' do
  if User.find_by(token: session[:user_token]).administrator?
    erb :admin_page
  else
    redirect '/sign_in'
  end
end

post '/' do
  session[:id] = SecureRandom.uuid
  Board.create(name: session[:id], screen_name: params[:board_name])
  redirect "/board_room/#{session[:id]}"
end

get '/board_room/:id' do
  data = Board.find_by(name: session[:id])
  @id = data.screen_name 

  user_attrs = { id: 1, name: "izumin" }

  if !request.websocket?
    erb :room
  else
    redis = EM::Hiredis.connect

    request.websocket do |ws|
      ws.onopen do
        redis.pubsub.subscribe(@id) do |msg|
          ws.send({ user: user_attrs, body: msg }.to_json)
        end
      end

      ws.onmessage do |msg|
        EM.next_tick do
          redis.publish(@id, msg).errback { |e| p e }
        end
      end

      ws.onclose do
        redis.pubsub.unsubscribe(@id)
      end
    end
  end
end
