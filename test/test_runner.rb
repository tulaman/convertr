require 'test/helper'

class TestRunner < Test::Unit::TestCase
  context "Runner" do
    setup do
      @runner = Convertr::Runner.new(%w{
        -d test/database.yml -c test/settings.yml -m 10
      })
    end
    should "should parse arguments from command line" do
      c = Convertr::Config.instance
      assert_equal 'test/database.yml', c.db_config_file
      assert_equal 'test/settings.yml', c.settings_file
      assert_equal 10, c.max_tasks
    end
  end
end
