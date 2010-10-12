require 'test/helper'

class TestVersion < Test::Unit::TestCase
  context "Convertr::Version" do
    setup do
      @version = File.read('VERSION').chomp
    end
    should "return valid version" do
      assert_equal @version, "#{Convertr::Version}"
    end
  end
end
