require 'bundler'
Bundler.require

require 'json'

set :server, 'thin'
set :sockets, Hash.new { |h, k| h[k] = [] }

get '/:id' do
  @id = params[:id]

  user_attrs = { id: 1, name: "izumin" }

  if !request.websocket?
    erb :index
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
