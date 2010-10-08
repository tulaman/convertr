require 'test/helper'

class TestTask < Test::Unit::TestCase
  context "Tasks" do
    should "have for_convertor scope" do
      assert_equal 0, Convertr::Task.for_convertor('unknown').length
    end
    should "have not_completed scope" do
      assert_equal 0, Convertr::Task.not_completed.length
    end
  end

  context "Task" do
    setup do
      @task = Convertr::Task.new
    end
    subject { @task }
    should belong_to(:file)
    should "be valid" do
      assert @task.valid?
    end
  end
end
