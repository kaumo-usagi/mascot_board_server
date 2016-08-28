require 'padrino-helpers'
require 'kaminari/sinatra'

get '/boards/:board_name/stamps.json' do
  stamps = Board.find_by(name: params[:board_name]).put_stamps
  stamps.map { |stamp| 
    { board_id: stamp.board_id,
      stamp_id: stamp.stamp_id, 
      x:        stamp.x, 
      y:        stamp.y 
    } }.to_json
end

post '/boards/:board_name/stamps.json' do
  board = Board.find_by(name: params[:board_name])
  if board
    data = JSON.parse(request.body.read)
    put_stamp = PutStamp.new(
      board_id: board.id,
      stamp_id: data["stamp_id"], 
      x:        data["x"], 
      y:        data["y"]
    )
    if put_stamp.save
      stamp = put_stamp.stamp
      res_body = { id: put_stamp.id, stamp_id: stamp.id, x: put_stamp.x, y: put_stamp.y, url: stamp.data.small.url }
      redis = EM::Hiredis.connect
      redis.publish("boards::#{board.id}::image::put", res_body.to_json)
      status 204
    else
      status 400
    end
  else
    status 400
  end
end

delete '/boards/:board_name/stamps/:stamp_id.json' do
  PutStamp.where(stamp_id: params[:stamp_id].to_i, board_id: params[:board_name].to_i)[0].delete
end


get '/boards/:board_name/texts.json' do
  texts = Board.find_by(name: params[:board_name]).put_texts
  texts.map { |text| 
    { board_id: text.board,
      body:     text.body, 
      x:        text.x, 
      y:        text.y,
    } }.to_json
end

post '/boards/:board_name/texts.json' do
  board = Board.find_by(name: params[:board_name])
  if board
    data = JSON.parse(request.body.read)
    puts "=" * 30
    p data["body"]
    puts "+" * 30
    text = PutText.new(
      board_id: board.id,
      body:     data["body"],
      x:        data["x"], 
      y:        data["y"]
    )
    if text.save
      redis = EM::Hiredis.connect
      redis.publish("boards::#{board.id}::text::put", text.to_json)
      status 204
    else
      status 400
    end
  else
    status 400
  end
end

delete '/boards/:board_name/stamps/:text_id.json' do
  PutText.find_by(text_id: params[:text_id].to_i, board_id: params[:board_name])
end

get '/stamps/:page.json' do
  stamps = Stamp.page(params[:page]).per(15)
  stamps.map{ |s| { id: s.id, url: s.data.url } }.to_json
end
