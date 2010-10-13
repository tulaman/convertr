require 'test/helper'

class TestConvertor < Test::Unit::TestCase
  context "Convertor" do
    setup do
      @convertor = Convertr::Convertor.new
    end

    should "be able to calculate thumbnails count" do # {{{
      assert_equal 3, @convertor.instance_eval { calc_thumbnails_count(600) }
      assert_equal 6, @convertor.instance_eval { calc_thumbnails_count(1200) }
      assert_equal 9, @convertor.instance_eval { calc_thumbnails_count(1800) }
      assert_equal 12, @convertor.instance_eval { calc_thumbnails_count(2400) }
      assert_equal 15, @convertor.instance_eval { calc_thumbnails_count(3000) }
      assert_equal 18, @convertor.instance_eval { calc_thumbnails_count(3600) }
      assert_equal 21, @convertor.instance_eval { calc_thumbnails_count(3700) }
      assert_equal 24, @convertor.instance_eval { calc_thumbnails_count(4260) }
    end
    # }}}
    should "find the right profile by bitrate" do # {{{
      assert_equal 'sd', @convertor.instance_eval("profile_by_bitrate(300)")
      assert_equal 'hd', @convertor.instance_eval("profile_by_bitrate(600)")
      assert_equal 'hdp', @convertor.instance_eval("profile_by_bitrate(1000)")
      assert_raise RuntimeError do
        @convertor.instance_eval("profile_by_bitrate(1234)")
      end
    end
    # }}}
    context "for some task with crop and deinterlace" do # should prepare valid shell command for ffmpeg {{{ 
      setup do
        task = Factory.create(:task, :bitrate => 600, :crop => true, :deinterlace => true)
        @convertor.stubs(:task).returns(task)
      end
      should "prepare valid command for ffmpeg" do
        assert_equal '/usr/bin/ffmpeg -y -i infile.avi -s 736x414 -ab 64k -ac 1 -acodec libfaac -ar 44100 -b 236k -bt 236k -cropbottom 8 -cropleft 16 -cropright 16 -croptop 10 -deinterlace  -pass 2 -threads 3 -vcodec libx264 -vpre hq-flash outfile.mpg',
          @convertor.instance_eval { mkcmd({'vpre' => 'hq-flash', 'pass' => 2}, 'sd', 'infile.avi', 'outfile.mpg', '16:9') }
      end
    end

    context "for some task with crop and without deinterlace" do
      setup do
        task = Factory.create(:task, :bitrate => 600, :crop => true, :deinterlace => false)
        @convertor.stubs(:task).returns(task)
      end
      should "prepare valid command for ffmpeg" do
        assert_equal '/usr/bin/ffmpeg -y -i infile.avi -s 736x414 -ab 64k -ac 1 -acodec libfaac -ar 44100 -b 236k -bt 236k -cropbottom 8 -cropleft 16 -cropright 16 -croptop 10 -pass 2 -threads 3 -vcodec libx264 -vpre hq-flash outfile.mpg',
          @convertor.instance_eval { mkcmd({'vpre' => 'hq-flash', 'pass' => 2}, 'sd', 'infile.avi', 'outfile.mpg', '16:9') }
      end
    end

    context "for some task without crop and without deinterlace" do
      setup do
        task = Factory.create(:task, :bitrate => 600, :crop => false, :deinterlace => false)
        @convertor.stubs(:task).returns(task)
      end
      should "prepare valid command for ffmpeg" do
        assert_equal '/usr/bin/ffmpeg -y -i infile.avi -s 640x480 -ab 64k -ac 1 -acodec libfaac -ar 44100 -b 236k -bt 236k -pass 2 -threads 3 -vcodec libx264 -vpre hq-flash outfile.mpg',
          @convertor.instance_eval { mkcmd({'vpre' => 'hq-flash', 'pass' => 2}, 'sd', 'infile.avi', 'outfile.mpg', '4:3') }
      end
    end

    context "for some task with unusual aspect (15:9) with crop" do
      setup do
        task = Factory.create(:task, :bitrate => 600, :crop => true, :deinterlace => false)
        @convertor.stubs(:task).returns(task)
      end
      should "prepare valid command for ffmpeg" do
        assert_equal '/usr/bin/ffmpeg -y -i infile.avi -s 672x408 -ab 64k -ac 1 -acodec libfaac -ar 44100 -b 236k -bt 236k -cropbottom 4 -cropleft 16 -cropright 16 -croptop 20 -pass 2 -threads 3 -vcodec libx264 -vpre hq-flash outfile.mpg',
          @convertor.instance_eval { mkcmd({'vpre' => 'hq-flash', 'pass' => 2}, 'sd', 'infile.avi', 'outfile.mpg', '15:9') }
      end
    end

    context "for some task with very unusual aspect (3:3)" do
      setup do
        task = Factory.create(:task, :bitrate => 600, :crop => false, :deinterlace => false)
        @convertor.stubs(:task).returns(task)
      end
      should "prepare valid command for ffmpeg" do
        assert_equal '/usr/bin/ffmpeg -y -i infile.avi -s 640x480 -ab 64k -ac 1 -acodec libfaac -ar 44100 -aspect 1.33333333 -b 236k -bt 236k -pass 2 -threads 3 -vcodec libx264 -vpre hq-flash outfile.mpg',
          @convertor.instance_eval { mkcmd({'vpre' => 'hq-flash', 'pass' => 2}, 'sd', 'infile.avi', 'outfile.mpg', '3:3') }
      end
    end
    #}}}
    context "for task with crop and deinterlace and file with aspect 4:3" do # {{{
      setup do
        @convertor.working_dir = '/tmp'
        file = Factory(:file, :aspect => '4:3', :filename => 'test.avi')
        @convertor.task = Factory(:task, :file => file, :crop => true, :deinterlace => true)
      end
      should "prepare valid shell command for thumbnail generation" do # {{{
        assert_equal "/usr/local/bin/tmaker -i /tmp/test.avi  -c 20  -d  -w 150 -h 112 -o /tmp/output/tmp 200 400 600",
          @convertor.instance_eval { make_thumbnails_cmd(3, 200, 150, nil, 2) }
      end # }}}
    end #}}}
    context "when source file is available locally" do # {{{
      setup do
        @convertor.working_dir = '/tmp/test_working_dir'
        FileUtils.mkpath '/tmp/test_working_dir'
        FileUtils.touch '/tmp/test_working_dir/test.avi'
        Net::FTP.expects(:open).never
      end
      should "return immediately on attempt to fetch file" do
        assert_nil @convertor.instance_eval { fetch_file('ftp://example.com/test.avi', 'test.avi') }
      end
    end # }}}
    context "when source file is not available locally" do # {{{
      setup do
        @convertor.working_dir = '/tmp/test_working_dir'
        FileUtils.rm_rf '/tmp/test_working_dir'
      end

      context "and ftp server works fine" do
        setup do
          ftp = mock()
          ftp.expects(:login).with('test','test')
          ftp.expects(:getbinaryfile).with('test.avi', '/tmp/test_working_dir/test.avi.part', 1024)
          ftp.expects(:close)
          Net::FTP.expects(:new).with('example.com', nil, nil, nil).returns(ftp)
        end
        should "download file by FTP" do
          assert_equal 0, @convertor.instance_eval { fetch_file('ftp://example.com/test.avi', 'test.avi') }
          assert !File.exists?('/tmp/test_working_dir/test.avi.part')
          assert File.exists?('/tmp/test_working_dir/test.avi')
        end
      end

      context "and ftp server doesn't work" do
        setup do
          ftp = mock()
          ftp.expects(:login).with('test','test')
          ftp.expects(:getbinaryfile).raises(Net::FTPError)
          ftp.expects(:close)
          Net::FTP.expects(:new).with('example.com', nil, nil, nil).returns(ftp)
        end
        should "remove tmp file and raise error" do
          assert_raise Net::FTPError do
            @convertor.instance_eval { fetch_file('ftp://example.com/test.avi', 'test.avi') }
          end
          assert !File.exists?('/tmp/test_working_dir/test.avi.part')
        end
      end
    end # }}}
  end

  context "Convertor ran with max_tasks=2" do
    setup do
      @convertor = Convertr::Convertor.new(2)
    end

    context "after successful processing first and failure on second task" do # {{{
      setup do
        @task_success = Factory(:task)
        @task_failure = Factory(:task)
        @convertor.scheduler.stubs(:schedule_next_task).returns(@task_success).then.returns(@task_failure)
        @convertor.stubs(:process_task).returns('SUCCESS').then.returns('FAILURE')
        @convertor.run
      end
      should "exit" do
        assert_equal 2, @convertor.tasks
      end
      should "update first task with success" do
        assert_equal 'SUCCESS', @task_success.convert_status
        assert_in_delta Time.now.to_i, @task_success.convert_stopped_at.to_i, 1
      end
      should "update second task with failure" do
        assert_equal 'FAILURE', @task_failure.convert_status
        assert_in_delta Time.now.to_i, @task_failure.convert_stopped_at.to_i, 1
      end
    end # }}}
  end
end
