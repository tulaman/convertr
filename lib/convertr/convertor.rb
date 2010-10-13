require 'logger'
require 'uri'
require 'net/ftp'

class Hash # {{{ small hack for syntax sugar - hash merging by +
  def +(h)
    self.merge(h)
  end
end # }}}

class File # {{{ filename without extension
  def self.filename(filepath)
    File.basename(filepath, File.extname(filepath))
  end
end # }}}

module Convertr
  class Convertor
    CONVERTOR_STOPFILE = 'stop.convertr'
    CONVERTOR_PAUSEFILE = 'pause.convertr'
    CONVERTOR_PAUSE_DELAY = 120
    CONVERTOR_MAX_FETCH_TIME = 600

    attr_accessor :scheduler, :max_tasks, :hostname, :initial_dir, :file, :task, :filepath, :work_path, :tasks, :working_dir

    def initialize(max_tasks = 0, scheduler = nil) # инициализация конертера {{{
      @max_tasks = max_tasks
      @logger = Logger.new($stderr)
      @initial_dir = Dir.pwd
      @scheduler = Convertr::SchedulerFactory.create(scheduler)
      @hostname = `hostname`.chomp
      @conf = Convertr::Config.instance
      @tasks = 0
    end # }}}

    def run # запуск конвертора {{{
      loop do
        break if File.exists? CONVERTOR_STOPFILE
        if !File.exists?(CONVERTOR_PAUSEFILE) and @task = @scheduler.schedule_next_task(@hostname)
          @task.update_attributes(
            :convert_status => process_task,
            :convert_stopped_at => Time.now
          )
          break if @max_tasks > 0 && (@tasks += 1) >= @max_tasks
        else
          sleep(CONVERTOR_PAUSE_DELAY) && next
        end
      end
    end # }}}

    private

    def process_task # выполнение конкретной задачи на конвертацию {{{
      @file = @task.file
      @filepath = File.join(@conf.tmp_dir, @file.filename)
      @working_dir = File.join( File.dirname(@filepath), File.filename(@filepath) )
      @logger.info("Started #@filepath")
      begin
        fetch_file(@file.source_location, @file.filename)
        FileUtils.cd @working_dir
        process_profile(profile_by_bitrate(@task.bitrate))
        if @task.bitrate == 600
          count = calc_thumbnails_count(@file.duration)
          interval = (@file.duration / count).to_i
          system(make_thumbnails_cmd(count, interval, 150, nil, 2)) or raise "thumbnails generation failed #{$?}"
        end
        @logger.info("Done #@filepath")
      rescue StandardError => e
        @logger.error e.message
        return 'FAILURE'
      ensure
        FileUtils.cd @initial_dir
      end
      'SUCCESS'
    end # }}}

    def fetch_file(source_url, filename) # скачивание файла по FTP {{{
      FileUtils.mkpath(@working_dir)
      dst_file = ::File.join(@working_dir, ::File.basename(filename))
      tmp_file = dst_file + ".part"
      started_at = Time.now
      loop do
        return if ::File.exists? dst_file
        if ::File.exists? tmp_file
          sleep(CONVERTOR_PAUSE_DELAY)
          if Time.now > started_at + CONVERTOR_MAX_FETCH_TIME
            FileUtils.rm_f tmp_file
          else
            next
          end
        end
        FileUtils.touch tmp_file
        break
      end

      url = URI.parse(source_url)
      Net::FTP.open(url.host) do |ftp|
        begin
          ftp.login(@conf.ftp_user, @conf.ftp_pass)
          ftp.getbinaryfile(url.path, tmp_file, 1024)
        rescue StandardError => e
          FileUtils.rm_f tmp_file
          raise e
        end
      end

      FileUtils.move tmp_file, dst_file
    end # }}}

    def profile_by_bitrate(bitrate) # bitrate -> profile {{{
      case bitrate
      when 300 then 'sd'
      when 600 then 'hd'
      when 1000 then 'hdp'
      else
        raise "Unsupported bitrate '#{bitrate}'"
      end
    end # }}}

    def process_profile(pname) # конвертация, согласно профилю # {{{
      profile = @conf.enc_profiles[pname]
      outfile = File.join(@working_dir, File.filename(@file.filename), "-#{pname}-0.mp4")
      infile = File.join(@working_dir, File.basename(@file.filename))
      output_dir = File.join(@conf.output_dir, @working_dir)
      FileUtils.mkpath output_dir unless File.exists? output_dir
      FileUtils.chdir output_dir
      FileUtils.mkdir pname unless File.exists? pname
      FileUtils.chdir pname
      
      @conf.enc_pass.each_with_index do |enc_pass_params, i|
        cmd = mkcmd(enc_pass_params, pname, infile, i == 0 ? '/dev/null' : outfile, @file.aspect)
        @logger.info(cmd)
        system(cmd) or raise "system #{cmd} failed: #{$?}"
      end

      outfile2 = File.join(@working_dir, File.filename(@file.filename), "-#{pname}.mp4")
      cmd = "#{@conv.qtfaststart} #{outfile} #{outfile2}"
      system(cmd) or FileUtils.rm_f(outfile) && raise("system #{cmd} failed: #{$?}")
      FileUtils.cd '..'
      FileUtils.rm_rf pname
    end # }}}

    def make_thumbnails_cmd(count, interval, w, h, postfix) # генерация тумбнейлов {{{
      file = task.file
      w = (h * file.float_aspect).to_i if h && w.nil?
      h = (w / file.float_aspect).to_i if file.aspect && w && h.nil?
      tstamps = (1..count).collect {|i| i * interval}
      params = ''
      params += ' -c 20 ' if task.crop?
      params += ' -d ' if task.deinterlace?
      infile = ::File.join(@working_dir, ::File.basename(file.filename))
      output_dir = ::File.join(@conf.output_dir, @working_dir)
      pattern = ::File.join(@working_dir, ::File.filename(file.filename), "-%d-#{postfix}.jpg")
      "#{@conf.tmaker} -i #{infile} #{params} -w #{w} -h #{h} -o #{output_dir} #{tstamps.join(' ')}"
    end # }}}

    def mkcmd(enc_pass, pname, infile, outfile, aspect) # подготовка команды на конвертацию {{{
      float_aspect = aspect.split(':').first.to_f / aspect.split(':').last.to_f
      params = @conf.enc_global + enc_pass + @conf.enc_profiles[pname]
      # we must deinterlace movies taken from sat. dvd and rips don't have to be deinterlaced
      params['deinterlace'] = '' if task.deinterlace? # option w/o a value
      (w, h) = case
        when aspect == '4:3' then [640, 480]
        when aspect == '16:9' then [704, 396]
        when float_aspect > 16.0 / 9.0 then [704, (704.0 / float_aspect).to_i]
        when float_aspect < 16.0 / 9.0 && float_aspect > 4.0 / 3.0 then [640, (640.0 / float_aspect).to_i]
        else 
          params['aspect'] = '1.33333333'
          [640, 480]
        end
      # Frame size must be a multiple of 2
      h -= 1 if h.odd?
      if task.crop?
        (params['croptop'], params['cropbottom'], params['cropleft'], params['cropright']) =
          case aspect
          when '16:9'
            w += 32 ; h += 18
            [10, 8, 16, 16]
          else # '4:3', '5:3' etc
            w += 32 ; h += 24
            [20, 4, 16, 16]
          end
      end
      "#{@conf.ffmpeg} -y -i #{infile} -s #{w}x#{h} #{params.map {|k, v| "-#{k} #{v}"}.sort.join(' ')} #{outfile}"
    end # }}}

    def calc_thumbnails_count(seconds) # выбор количества тумбнейлов {{{
      case (seconds / 60).to_i
      when  0..10 then 3
      when 10..20 then 6
      when 20..30 then 9
      when 30..40 then 12
      when 40..50 then 15
      when 50..60 then 18 
      when 60..70 then 21
      else 24
      end
    end # }}}
  end
end
