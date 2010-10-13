require 'test/helper'

class TestScheduler < Test::Unit::TestCase
  context "Base Scheduler" do
    setup do
      @scheduler = Convertr::Scheduler::Base.new
    end
    should "raise exception on calling abstract methods" do
      assert_raise RuntimeError do
        @scheduler.instance_eval { get_task_for_schedule('convertor1') }
      end
    end
  end
end
