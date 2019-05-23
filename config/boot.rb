ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../../Gemfile', __FILE__ )
require 'bundler/setup'

Bundler.require
require 'yaml'
require 'json'
require 'logger'

Dir['./lib/**/*.rb'].each { |f| require f }
require_relative 'app'

Dir['./config/initializers/*.rb'].each { |f| require f }
