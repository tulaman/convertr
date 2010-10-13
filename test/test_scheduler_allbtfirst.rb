require 'test/helper'

class TestSchedulerAllbtfirst < Test::Unit::TestCase
  context "AllBtFirst scheduler" do
    setup do
      @scheduler = Convertr::SchedulerFactory.create('AllBtFirst')
    end
    should "find first task assigned for convertor" do
      assert_equal 3, @scheduler.get_task_for_schedule('convertor1').id
    end
  end
end
