require 'bundler/setup'
Bundler.require
require './models.rb'
require './carrier_wave.rb'

[0,1,2,3,4,5,6,7,8,9].each { |i| s = Stamp.new; File.open("seed_file/sample#{i}.jpg") { |f| s.data = f } ;s.save }
Board.create(name: SecureRandom.uuid, screen_name: "KAUMO-HACKATHON")
User.create(name: "Admin", token: SecureRandom.uuid, mail: "admin@gmail.com", administrator: true, password: "kaumo-usagi", password_confirmation: "kaumo-usagi")
PutText.create(board_id: 1, x: 100, y: 200, body: "てすとおおおおおおお！"); PutText.create(board_id: 1, x: 300, y: 100, body: "おなかすいた")
PutStamp.create(board_id: 1, x: 100, y: 200, stamp_id: 1); PutStamp.create(board_id: 1, x: 300, y: 100, stamp_id: 4)
