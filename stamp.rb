post '/boards/:board_name/stamps.json' do
  data = JSON.parse(request.body.read)
  stamps = PutStamps.new(
    board_id: params[:board_name],
    stamp_id: data["stamp_id"], 
    x: data["x"], 
    y: data["y"]
  )
  status(stamps.save ?  204 : 404)
end

delete '/boards/:board_name/stamps.json' do
  data = JSON.parse(request.body.read)
  PutStamps.find_by(id: data["stamp_id"]).delete
end
