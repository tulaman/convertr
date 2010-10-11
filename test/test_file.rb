require 'test/helper'

class TestFile < Test::Unit::TestCase
  context "File class" do
    should "have without_convertor scope" do
      files = Convertr::File.without_convertor
      assert_equal 2, files.size
      assert_equal 3, files.first.id
    end

    should "have with_convertor scope" do
      files = Convertr::File.with_convertor('convertor1')
      assert_equal 2, files.size
      assert_equal 1, files.first.id
    end
  end
  context "File" do
    setup do
      @file = Convertr::File.new
    end
    subject { @file }
    should have_many(:tasks)
    should "be valid" do
      assert @file.valid?
    end
  end
end
