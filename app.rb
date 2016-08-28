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
enable :sessions

set :server, 'thin'

EVENT_TYPES = {
  mousemove:  "mousemove",
  message:    "message",
  user:       "user",
  text_put:   "text::put",
  image_put:  "image::put",
  text_drag:  "text::drag",
  image_drag: "image::drag",
  text_drag_end:  "text::drag::end",
  image_drag_end: "image::drag::end",
}.freeze

get '/' do
  @boards = Board.all
  erb :index
end

get '/sign_up' do
  @form_action, @form_title, @submit_text = '/sign_up', "SignupPage", "登録"
  erb :sign
end

post '/sign_up' do
  session[:user_token] = SecureRandom.uuid
  User.create(mail: params[:mail], token: session[:user_token], password: params[:password], password_confirmation: params[:password])
  redirect '/admin'
end

get '/sign_in' do
  @form_action, @form_title, @submit_text = '/sign_in' ,"SigninPage", "ログイン"
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
  Board.create!(name: name, screen_name: params[:board_name])
  redirect "/boards/#{name}"
end

get '/boards/:id' do
  @board = Board.find_by(name: params[:id])
  user = User.find_by(id: session[:user_id])
  if user
    @board.users << user
  else
    user = @board.users.create!(name: User.random_name, color: User.random_color, password: "password", password_confirmation: "password")
    session[:user_id] = user.id
  end

  if @board.nil?
    redirect "/"
  elsif !request.websocket?
    erb :room , layout: :layout 
  else
    redis = EM::Hiredis.connect
    channel_base = "boards::#{@board.id}"
    channel_user = "#{channel_base}::user"
    channel_message = "#{channel_base}::message"
    channel_mouse = "#{channel_base}::cursor::move"
    channel_text_put = "#{channel_base}::text::put"
    channel_image_put = "#{channel_base}::image::put"
    channel_text_drag = "#{channel_base}::text::drag"
    channel_image_drag = "#{channel_base}::image::drag"

    user_json = { id: user.id, name: user.name, color: user.color }

    request.websocket do |ws|
      ws.onopen do
        redis.publish(channel_user, user_json.to_json).errback { |e| p e }
        @board.users.each do |u|
          ws.send({ type: EVENT_TYPES[:user], data: { user: { id: u.id, name: u.name, color: u.color } } }.to_json) if u.id != user.id
        end

        redis.pubsub.subscribe(channel_user) do |msg|
          json = JSON.parse(msg)
          ws.send({ type: EVENT_TYPES[:user], data: { user: json } }.to_json)
        end
        redis.pubsub.subscribe(channel_message) do |msg|
          json = JSON.parse(msg)
          ws.send({ type: EVENT_TYPES[:message], data: { user: json["user"], body: json["body"] } }.to_json)
        end
        redis.pubsub.subscribe(channel_mouse) do |msg|
          json = JSON.parse(msg)
          ws.send({ type: EVENT_TYPES[:mousemove], data: { user: json["user"], position: json["position"], drawing: json["drawing"] } }.to_json)
        end
        redis.pubsub.subscribe(channel_text_put) do |msg|
          json = JSON.parse(msg)
          ws.send({ type: EVENT_TYPES[:text_put], data: { text: json } }.to_json)
        end
        redis.pubsub.subscribe(channel_image_put) do |msg|
          json = JSON.parse(msg)
          ws.send({ type: EVENT_TYPES[:image_put], data: { image: json } }.to_json)
        end
        redis.pubsub.subscribe(channel_text_drag) do |msg|
          json = JSON.parse(msg)
          ws.send({ type: EVENT_TYPES[:text_drag], data: { text: json } }.to_json) unless json["user"]["id"] == user.id
        end
        redis.pubsub.subscribe(channel_image_drag) do |msg|
          json = JSON.parse(msg)
          ws.send({ type: EVENT_TYPES[:image_drag], data: { image: json } }.to_json) unless json["user"]["id"] == user.id
        end
      end

      ws.onmessage do |msg|
        EM.next_tick do
          json = JSON.parse(msg)
          case json["type"]
          when EVENT_TYPES[:message]
            redis.publish(channel_message, msg).errback { |e| p e }
          when EVENT_TYPES[:mousemove]
            json["user"] = user_json
            redis.publish(channel_mouse, json.to_json).errback { |e| p e }
            if json["drawing"]
              # TODO: パスの永続化
            end
          when EVENT_TYPES[:text_drag]
            json["user"] = user_json
            redis.publish(channel_text_drag, json.to_json).errback { |e| p e }
          when EVENT_TYPES[:text_drag_end]
            json["user"] = user_json
            redis.publish(channel_text_drag, json.to_json).errback { |e| p e }
            PutText.find(json["id"]).update(x: json["position"]["x"], y: json["position"]["y"])
          when EVENT_TYPES[:image_drag]
            json["user"] = user_json
            redis.publish(channel_image_drag, json.to_json).errback { |e| p e }
          when EVENT_TYPES[:image_drag_end]
            json["user"] = user_json
            redis.publish(channel_image_drag, json.to_json).errback { |e| p e }
            PutStamp.find(json["id"]).update(x: json["position"]["x"], y: json["position"]["y"])
          end
        end
      end

      ws.onclose do
        warn("close websocket connection")
        redis.pubsub.unsubscribe(channel_message)
      end
    end
  end
end
