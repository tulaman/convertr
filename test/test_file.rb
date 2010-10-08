require 'test/helper'

class TestFile < Test::Unit::TestCase
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
