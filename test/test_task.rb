require 'test/helper'

class TestTask < Test::Unit::TestCase
  context "Tasks" do
    should "have for_convertor scope" do
      assert_equal 2, Convertr::Task.for_convertor('convertor1').size
    end
    should "have not_completed scope" do
      assert_equal 3, Convertr::Task.not_completed.size
    end
    should "have without_convertor scope" do
      assert_equal 1, Convertr::Task.without_convertor.first.id
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
