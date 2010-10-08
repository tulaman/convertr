require 'test/helper'

class TestFile < Test::Unit::TestCase
  def setup
    Convertr::Runner.new([
      '--db_config', '/home/lucky/devel/videomore/config/database.yml',
      '-c', '/home/lucky/devel/videomore/config/settings.yml'
    ]).run
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
