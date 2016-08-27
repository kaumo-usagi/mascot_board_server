require 'bundler/setup'
Bundler.require

if development?
    ActiveRecord::Base.establish_connection("sqlite3:db/development.db")
end


class Stamp < ActiveRecord::Base
  has_many :put_stamps
  has_many :stamps, through: :put_stamps 
end

class User < ActiveRecord::Base
  belongs_to :board
  validates :name, uniqueness: true
  has_secure_password
  validates :mail,
    presence: true,
    format: {with:/.+@.+/}
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
