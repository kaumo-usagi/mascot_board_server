require 'bundler'
Bundler.require
require 'sinatra/reloader' if development?
require './models'
require 'json'
require 'securerandom'

use Rack::Session::Cookie
enable :sessions

set :server, 'thin'

EVENT_TYPES = {
  mousemove:  "mousemove",
  message:    "message",
  user:       "user"
}.freeze

ANONYMOUS_USER_NAMES = [
  "カピバラ",
  "カモノハシ",
  "うんこ",
  "ベンガルトラ",
  "インドゾウ",
  "イソギンチャク",
  "ホワイトライオン",
  "コウテイペンギン",
  "アホウドリ",
  "ドードー",
  "クマノミ"
].map { |name| "匿名#{name}" }.freeze

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

post "/boards/:board_name/users.json" do
  board = Board.find_by(name: params[:board_name])
  json user.to_json
end

post '/boards' do
  name = SecureRandom.uuid
  Board.create(name: name, screen_name: params[:board_name])
  redirect "/boards/#{name}"
end

get '/boards/:id' do
  @board = Board.find_by(name: params[:id])
  user = User.find_by(id: session[:user_id])
  if user
    @board.users << user
  else
    user = @board.users.create!(name: ANONYMOUS_USER_NAMES.sample, password: "password", password_confirmation: "password")
    session[:user_id] = user.id
  end

  if @board.nil?
    redirect "/"
  elsif !request.websocket?
    erb :room
  else
    redis = EM::Hiredis.connect
    channel_base = "boards::#{@board.id}"
    channel_message = "#{channel_base}::message"
    channel_mouse = "#{channel_base}::mouse"

    user_json = { id: user.id, name: user.name }

    request.websocket do |ws|
      ws.onopen do
        ws.send({ type: EVENT_TYPES[:user], user: user_json }.to_json)

        redis.pubsub.subscribe(channel_message) do |msg|
          json = JSON.parse(msg)
          ws.send({ type: EVENT_TYPES[:message], user: json["user"], body: json["body"] }.to_json)
        end
        redis.pubsub.subscribe(channel_mouse) do |msg|
          json = JSON.parse(msg)
          ws.send({ type: EVENT_TYPES[:mousemove], user: json["user"], position: json["position"] }.to_json)
        end
      end

      ws.onmessage do |msg|
        EM.next_tick do
          json = JSON.parse(msg)
          case json["type"]
          when EVENT_TYPES[:message]
            redis.publish(channel_message, msg).errback { |e| p e }
          when EVENT_TYPES[:mousemove]
            redis.publish(channel_mouse, msg).errback { |e| p e }
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
