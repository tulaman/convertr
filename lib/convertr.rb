require 'optparse'
require 'ostruct'
require 'yaml'
require 'active_record'
require 'active_record/railtie'
require 'convertr/migration'
require 'convertr/file'
require 'convertr/task'

module Convertr
  module Version
    class << self
      def to_s
        File.read( File.join(File.dirname(__FILE__), '..', 'VERSION') ).chomp
      end
    end
  end

  class OptParser
    def self.parse(args)
      options = OpenStruct.new
      options.db_config = "~/.convertr/database.yml"
      options.config = "~/.convertr/settings.yml"
      options.max_tasks = 0
      options.force_reset_database = false
      opts = OptionParser.new do |opts|
        opts.banner = "Usage: convertr [options]"
        opts.separator ""
        opts.separator "Specific options:"

        opts.on("-d", "--db_config [PATH_TO_DB_CONFIG]",
                "Specify path to database.yml file") do |dbc|
          options.db_config = dbc
        end

        opts.on("-c", "--config [PATH_TO_CONFIG]",
                "Specify path to settings.yml file") do |c|
          options.config = c
        end

        opts.on("-m", "--max_tasks N", Integer,
                "Specify the maximum tasks to complete") do |m|
          options.max_tasks = m
        end

        opts.on("-f", "--force",
                "Force recreating database tables") do |f|
          options.force = f
        end
      end
      opts.parse!
      options
    end
  end

  class Runner
    attr_reader :db_config, :config, :options

    def initialize(opts)
      @options = Convertr::OptParser.parse(opts)
      enviroment = ENV['RAILS_ENV'] || 'development'
      @db_config = YAML.load_file(@options.db_config)[enviroment]
      @config = YAML.load_file(@options.config)[enviroment]
    end

    def run
      ActiveRecord::Base.establish_connection(@db_config)
      Convertr::Migration.down if @options.force
      Convertr::Migration.up unless Convertr::File.table_exists? && Convertr::Task.table_exists?
    end
  end
end
