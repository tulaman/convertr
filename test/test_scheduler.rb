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

    context "after scheduling next task" do
      setup do
        @task = Factory.build :task
        @scheduler.expects(:get_task_for_schedule).with('convertor1').returns(@task)
        @scheduler.schedule_next_task('convertor1')
      end

      should "update task accordingly" do
        assert_equal 'PROGRESS', @task.convert_status
        assert_in_delta Time.now.to_i, @task.convert_started_at.to_i, 1
      end

      should "update file accordingly" do
        assert_equal "convertor1", @task.file.convertor
      end
    end
  end
end
