require 'ostruct'
require 'active_record'
require 'active_record/railtie'
require 'convertr/runner'
require 'convertr/migration'
require 'convertr/scheduler'
require 'convertr/scheduler_factory'

module Convertr
  module Version
    class << self
      def to_s
        File.read( File.join(File.dirname(__FILE__), '..', 'VERSION') ).chomp
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
    config.settings = YAML.load_file(config.settings_file)[enviroment] if config.settings_file
    self.init!
  end

  def self.init!
    conf = Config.instance
    ActiveRecord::Base.establish_connection(conf.db_config)
    require 'convertr/file'
    require 'convertr/task'
    Convertr::Migration.down if conf.force
    Convertr::Migration.up unless Convertr::File.table_exists? && Convertr::Task.table_exists?
  end
end
