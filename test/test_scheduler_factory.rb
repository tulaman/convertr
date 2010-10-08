require 'helper'

class TestSchedulerFactory < Test::Unit::TestCase
  context "SchedulerFactory" do
    should "create instance of AllBtFirst by default" do
      assert_instance_of Convertr::Scheduler::AllBtFirst, Convertr::SchedulerFactory.create
    end

    should "create instance of appropriate scheduler" do
      assert_instance_of Convertr::Scheduler::Bt600First, Convertr::SchedulerFactory.create('Bt600First')
    end

    should "return object inherited from base scheduler" do
      assert_kind_of Convertr::Scheduler::Base, Convertr::SchedulerFactory.create
    end
  end
end
