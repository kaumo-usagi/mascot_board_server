require 'bundler'
Bundler.require
require 'sinatra/reloader' if development?
require './models'
require 'json'
require 'securerandom'

use Rack::Session::Cookie
set :server, 'thin'
set :sockets, Hash.new { |h, k| h[k] = [] }

get '/' do
  if session[:user_name]
    @room_list = Room.all
    erb :index
  else
    erb :index
  end
end

post '/' do
  session[:id] = SecureRandom.uuid
  User.create(name: session[:id], screen_name: params[:user_name])
  redirect '/'
end

get '/room/:id' do
  @id = params[:id]

  user_attrs = { id: 1, name: "izumin" }

  if !request.websocket?
    erb :room
  else
    request.websocket do |ws|
      ws.onopen do
        ws.send({ user: user_attrs, body: "Hello World!" }.to_json)
        settings.sockets[@id] << ws
      end

      ws.onmessage do |msg|
        EM.next_tick do
          settings.sockets[@id].each do |s|
            s.send({ user: user_attrs, body: msg }.to_json)
          end
        end
      end

      ws.onclose do
        warn("websocket closed")
        settings.sockets[@id].delete(ws)
      end
    end
  end
end
