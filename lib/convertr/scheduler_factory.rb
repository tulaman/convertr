require 'convertr/scheduler'
Dir[File.join(File.dirname(__FILE__), 'scheduler', '*')].each {|f| require f if File.file? f}

module Convertr
  class SchedulerFactory
    def self.create(name = 'AllBtFirst')
      Convertr::Scheduler.const_get(name).new
    end
  end
end
