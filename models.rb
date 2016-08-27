require 'bundler/setup'
Bundler.require

if development?
    ActiveRecord::Base.establish_connection("sqlite3:db/development.db")
end


class Stamp < ActiveRecord::Base
end

class User < ActiveRecord::Base
end

class Board < ActiveRecord::Base
end
