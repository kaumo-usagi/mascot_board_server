require 'bundler/setup'
Bundler.require

if development?
    ActiveRecord::Base.establish_connection("sqlite3:db/development.db")
end


class Stamp < ActiveRecord::Base
  belongs_to :board
end

class User < ActiveRecord::Base
  has_many :boards
end

class Board < ActiveRecord::Base
  has_many :users
  has_many :stamps
end
