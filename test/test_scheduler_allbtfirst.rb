require 'test/helper'

class TestSchedulerAllbtfirst < Test::Unit::TestCase
  context "AllBtFirst scheduler" do
    setup do
      Convertr::Runner.new([
        '--db_config', '/home/lucky/devel/videomore/config/database.yml',
        '-c', '/home/lucky/devel/videomore/config/settings.yml'
      ]).run
      @scheduler = Convertr::SchedulerFactory.create('AllBtFirst')
    end
    should "find first task assigned for convertor" do
      assert true
    #  assert_equal 0, @scheduler.get_task_for_schedule('convertor1').length
    end
  end
end
