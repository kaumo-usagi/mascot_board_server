require 'bundler'
Bundler.require
require './carrier_wave'
require './app'

use ActiveRecord::ConnectionAdapters::RefreshConnectionManagement

register Kaminari::Helpers::SinatraHelpers

run Sinatra::Application
