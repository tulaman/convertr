require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'shoulda/active_record'
require 'factory_girl'
require 'mocha'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
#$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'convertr'
Convertr.configure do |c|
  c.db_config_file = './test/database.yml'
  c.settings_file = './test/settings.yml'
end
require 'factories/files'
require 'factories/tasks'

class Test::Unit::TestCase
end
