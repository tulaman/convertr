require 'ostruct'
require 'active_record'
require 'active_record/railtie'
require 'convertr/runner'
require 'convertr/scheduler'
require 'convertr/scheduler_factory'
require 'convertr/convertor'

module Convertr
  module Version
    class << self
      def to_s
        ::File.read( ::File.join(::File.dirname(__FILE__), '..', 'VERSION') ).chomp
      end
    end
  end

  class Config < OpenStruct
    include Singleton
  end

  def self.configure(config = nil)
    config ||= Config.instance
    yield Config.instance if block_given?
    enviroment = ENV['RAILS_ENV'] || 'development'
    config.db_config = YAML.load_file(config.db_config_file)[enviroment]
    if config.settings_file
      YAML.load_file(config.settings_file)[enviroment]['convertor'].each do |k, v|
        config.send("#{k}=", v)
      end
    end
    self.init!
  end

  def self.init!
    conf = Config.instance
    ActiveRecord::Base.establish_connection(conf.db_config)
    require 'convertr/file'
    require 'convertr/task'
    $stderr.puts "Tables not found" && exit(1) unless Convertr::File.table_exists? && Convertr::Task.table_exists?
  end
end
