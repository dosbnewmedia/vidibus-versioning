require 'simplecov'
SimpleCov.start do
  add_filter '/spec/'
end

$:.unshift File.expand_path('../../', __FILE__)

require 'rspec'
require 'timecop'
require 'vidibus-versioning'
require 'database_cleaner'

Dir['spec/support/**/*.rb'].each { |f| require f }

Mongo::Logger.logger.level = Logger::FATAL

Mongoid.configure do |config|
  config.connect_to('vidibus-versioning_test')
end

RSpec.configure do |config|
  config.before(:each) do
    Mongoid::Clients.default.collections.
      select {|c| c.name !~ /system/}.each(&:drop)
  end
  config.before(:suite) do
    DatabaseCleaner.clean_with(:truncation)
  end

  config.before(:each) do
    DatabaseCleaner.start
  end

  config.after(:each) do
    Timecop.return
    DatabaseCleaner.clean
  end
end
