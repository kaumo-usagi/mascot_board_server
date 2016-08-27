require 'bundler/setup'
Bundler.require
require 'carrierwave/orm/activerecord'

ActiveRecord::Base.establish_connection("sqlite3:db/development.db")

class ImageUploader < CarrierWave::Uploader::Base
  storage :fog
end

class Stamp < ActiveRecord::Base
  mount_uploader :data, ImageUploader
  has_many :put_stamps
  has_many :stamps, through: :put_stamps 
end

class User < ActiveRecord::Base
  has_many :board_users
  has_many :boards, through: :board_users

  has_secure_password
  validates :password, confirmation: true,
    unless: Proc.new { |a| a.password.blank? } 
end

class Board < ActiveRecord::Base
  has_many :users
  has_many :put_stamps
  has_many :stamps, through: :put_stamps 
  has_many :put_texts
end

class PutStamp < ActiveRecord::Base
  belongs_to :board
  belongs_to :stamp
end

class PutText < ActiveRecord::Base
  belongs_to :board
end
