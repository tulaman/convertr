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

    attr_accessor :scheduler, :max_tasks, :hostname, :initial_dir, :file, :task, :tasks, :logger

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
      @logger.info("Started #{original_file}")
      begin
        FileUtils.mkpath(indir)
        FileUtils.cd(indir)
        fetch_file(@file.location, @file.filename)
        process_profile(profile_by_bitrate(@task.bitrate))
        if @task.bitrate == 600
          count = calc_thumbnails_count(@file.duration)
          interval = (@file.duration / count).to_i
          system(make_thumbnails_cmd(count, interval, 150, nil, 2)) or raise "thumbnails generation failed #{$?}"
        end
        @logger.info("Done #{original_file}")
      rescue StandardError => e
        @logger.error e.message
        return 'FAILURE'
      ensure
        FileUtils.cd @initial_dir
      end
      'SUCCESS'
    end # }}}

    # Уже находясь в нужной директории, скачиваем файл по
    # source_url через FTP во временный файл filename.part
    # затем переименовываем его в filename
    # Если файл уже скачан, завершаем работу
    # Если находим временный файл - ждём, т.к., возможно
    # другой процесс уже занят скачиванием файла, если
    # ожидание продлится больше некоторого времени, удаляем
    # временный файл и скачиваем самостоятельно
    def fetch_file(source_url, filename) # скачивание файла по FTP {{{
      tmp_file = filename + ".part"
      started_at = Time.now
      loop do
        return if ::File.exists? filename
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

      FileUtils.move tmp_file, filename
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
      outfile = filename_with_suffix("-#{pname}-0.mp4") # => z-sd-0.mp4
      FileUtils.mkdir(pname) && FileUtils.chdir(pname)
      
      @conf.enc_pass.each_with_index do |enc_pass_params, i|
        cmd = mkcmd(enc_pass_params, pname, original_file, i == 0 ? '/dev/null' : outfile, @file.aspect)
        @logger.info(cmd)
        system(cmd) or raise "system #{cmd} failed: #{$?}"
      end

      outfile2 = filename_with_suffix("-#{pname}.mp4") # => z-sd.mp4
      cmd = "#{@conf.qtfaststart} #{outfile} #{outfile2}"
      system(cmd) or FileUtils.rm_f(outfile) && raise("system #{cmd} failed: #{$?}")
      FileUtils.rm_f(outfile)
      FileUtils.mkpath outdir # => /var/x/y
      FileUtils.move outfile2, outdir
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
      pattern = filename_with_suffix("-%d-#{postfix}.jpg")
      "#{@conf.tmaker} -i #{original_file} #{params} -w #{w} -h #{h} -o \"#{outdir}/#{pattern}\" #{tstamps.join(' ')}"
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

    # тут чёрт ногу сломит с этими картами директорий
    # /tmp/test.avi
    def original_file
      ::File.join(@conf.tmp_dir, ::File.basename(@file.filename))
    end

    # /tmp/test
    def indir
      ::File.join(@conf.tmp_dir, ::File.filename(@file.filename))
    end

    # /tmp/test/test
    def work_name
      ::File.join(@conf.tmp_dir, ::File.filename(@file.filename), ::File.filename(@file.filename))
    end

    # test + suffix
    def filename_with_suffix(suffix)
      ::File.filename(@file.filename) + suffix
    end

    # /var/x/y
    def outdir
      ::File.join(@conf.output_dir, ::File.dirname(@file.filename))
    end
  end
end
