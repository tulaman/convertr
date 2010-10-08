require 'optparse'

module Convertr
  class Runner
    class OptParser # {{{
      def self.parse(args)
        options = Convertr::Config.instance
        options.db_config_file = "~/.convertr/database.yml"
        options.settings_file = "~/.convertr/settings.yml"
        options.max_tasks = 0
        options.force_reset_database = false
        opts = OptionParser.new do |opts|
          opts.banner = "Usage: convertr [options]"
          opts.separator ""
          opts.separator "Specific options:"

          opts.on("-d", "--db_config_file [PATH_TO_DB_CONFIG]",
                "Specify path to database.yml file") do |dbc|
            options.db_config_file = dbc
          end

          opts.on("-c", "--settings_file [PATH_TO_CONFIG]",
                "Specify path to settings.yml file") do |c|
            options.settings_file = c
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
        opts.parse!(args)
        options
      end
    end # }}}

    attr_reader :db_config, :config, :options

    def initialize(opts) # {{{
      config = Convertr::Runner::OptParser.parse(opts)
      Convertr.configure(config)
    end
    # }}}
    def run # {{{
      puts "Running"
    end # }}}
  end
end
