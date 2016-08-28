require 'bundler/setup'
Bundler.require
require './models.rb'
require './carrier_wave.rb'

[0,1,2,3,4,5,6,7,8,9].each do |i| 
  s = Stamp.new
  File.open("seed_file/sample#{i}.jpg") do |f|
    s.data = f
  end
  s.save
end
Board.create(name: SecureRandom.uuid, screen_name: "KAUMO-HACKATHON")
User.create(name: "Admin", token: SecureRandom.uuid, mail: "admin@gmail.com", administrator: true, password: "kaumo-usagi", password_confirmation: "kaumo-usagi")
