post '/boards/:board_name/stamps.json' do
  data = JSON.parse(request.body.read)
  stamps = PutStamp.new(
    board_id: params[:board_name],
    stamp_id: data["stamp_id"], 
    x:        data["x"], 
    y:        data["y"]
  )
  status(stamps.save ?  204 : 404)
end

delete '/boards/:board_name/stamps/:stamp_id.json' do
  PutStamp.where(stamp_id: params[:stamp_id].to_i, board_id: params[:board_name].to_i)[0].delete
end


post '/boards/:board_name/texts.json' do
  data = JSON.parse(request.body.read)
  stamps = PutText.new(
    board_id: params[:board_name],
    text_id:  data["stamp_id"], 
    body:     data["text"],
    x:        data["x"], 
    y:        data["y"]
  )
  status(stamps.save ?  204 : 404)
end

delete '/boards/:board_name/stamps/:text_id.json' do
  PutText.find_by(text_id: params[:text_id].to_i, board_id: params[:board_name])
end
