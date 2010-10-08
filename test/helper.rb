require 'rubygems'
require 'test/unit'
require 'shoulda'
require 'shoulda/active_record'

$LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..', 'lib'))
$LOAD_PATH.unshift(File.dirname(__FILE__))
require 'convertr'

Convertr.configure() do |c|
  c.db_config_file = 'test/database.yml'
end

class Test::Unit::TestCase
end
