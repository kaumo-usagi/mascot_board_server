source "https://rubygems.org"

ruby "2.3.1"

gem "sinatra"
gem "sinatra-contrib"
gem "sinatra-activerecord"
gem "sinatra-websocket"
gem "rake"

group :development, :test do
  gem 'sqlite3'
end

group :production do
  gem 'pg'
end

gem "em-hiredis"
