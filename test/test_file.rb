require 'test/helper'

class TestFile < Test::Unit::TestCase
  context "File class" do
    should "have without_convertor scope" do
      files = Convertr::File.without_convertor
      assert_equal 3, files.first.id
    end

    should "have with_convertor scope" do
      files = Convertr::File.with_convertor('convertor1')
      assert_equal 1, files.first.id
    end
  end
  context "File" do
    setup do
      @file = Factory.build(:file, :aspect => '16:9')
    end
    subject { @file }
    should have_many(:tasks)
    should "be valid" do
      assert @file.valid?
    end
    should "be able to calculate aspect ratio as float" do
      assert_in_delta 1.777, @file.float_aspect, 0.001
    end
  end
end
