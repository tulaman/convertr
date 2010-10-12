require 'test/helper'

class TestConvertor < Test::Unit::TestCase
  context "Convertor" do
    setup do
      @convertor = Convertr::Convertor.new
    end

    should "be able to calculate thumbnails count" do
      assert_equal 3, @convertor.instance_eval("calc_thumbnails_count(600)")
      assert_equal 6, @convertor.instance_eval("calc_thumbnails_count(1200)")
      assert_equal 9, @convertor.instance_eval("calc_thumbnails_count(1800)")
    end

    should "find the right profile by bitrate" do
      assert_equal 'sd', @convertor.instance_eval("profile_by_bitrate(300)")
      assert_equal 'hd', @convertor.instance_eval("profile_by_bitrate(600)")
      assert_equal 'hdp', @convertor.instance_eval("profile_by_bitrate(1000)")
      assert_raise RuntimeError do
        @convertor.instance_eval("profile_by_bitrate(1234)")
      end
    end

    context "for some task with crop and deinterlace" do
      setup do
        task = Factory.create(:task, :bitrate => 600, :crop => true, :deinterlace => true)
        @convertor.stubs(:task).returns(task)
      end
      should "prepare valid command for ffmpeg" do
        assert_equal '/usr/bin/ffmpeg -y -i infile.avi -s 1118x414 -ab 64k -ac 1 -acodec libfaac -ar 44100 -b 236k -bt 236k -cropbottom 8 -cropleft 16 -cropright 16 -croptop 10 -deinterlace  -pass 2 -threads 3 -vcodec libx264 -vpre hq-flash outfile.mpg',
          @convertor.instance_eval { mkcmd({'vpre' => 'hq-flash', 'pass' => 2}, 'sd', 'infile.avi', 'outfile.mpg', '16:9') }
      end
    end

    context "for some task with crop and without deinterlace" do
      setup do
        task = Factory.create(:task, :bitrate => 600, :crop => true, :deinterlace => false)
        @convertor.stubs(:task).returns(task)
      end
      should "prepare valid command for ffmpeg" do
        assert_equal '/usr/bin/ffmpeg -y -i infile.avi -s 1118x414 -ab 64k -ac 1 -acodec libfaac -ar 44100 -b 236k -bt 236k -cropbottom 8 -cropleft 16 -cropright 16 -croptop 10 -pass 2 -threads 3 -vcodec libx264 -vpre hq-flash outfile.mpg',
          @convertor.instance_eval { mkcmd({'vpre' => 'hq-flash', 'pass' => 2}, 'sd', 'infile.avi', 'outfile.mpg', '16:9') }
      end
    end

    context "for some task without crop and without deinterlace" do
      setup do
        task = Factory.create(:task, :bitrate => 600, :crop => false, :deinterlace => false)
        @convertor.stubs(:task).returns(task)
      end
      should "prepare valid command for ffmpeg" do
        assert_equal '/usr/bin/ffmpeg -y -i infile.avi -s 704x396 -ab 64k -ac 1 -acodec libfaac -ar 44100 -b 236k -bt 236k -pass 2 -threads 3 -vcodec libx264 -vpre hq-flash outfile.mpg',
          @convertor.instance_eval { mkcmd({'vpre' => 'hq-flash', 'pass' => 2}, 'sd', 'infile.avi', 'outfile.mpg', '16:9') }
      end
    end
  end
end
