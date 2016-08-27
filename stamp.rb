post '/boards/:board_name/stamps.json' do
  data = JSON.parse(request.body.read)
  stamps = PutStamps.new(
    Board_id: params[:board_name],
    stamp_id: data["stamp_id"], 
    x: data["x"], 
    y: data["y"]
  )
  stamps.save ? status 204 : 404
end

delete '/boards/:board_name/stamps.json' do
  data = JSON.parse(request.body.read)
  PutStamps.find_by(id: data["stamp_id"]).delete
end
