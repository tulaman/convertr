namespace :convertr do
  task :load_config do
    $LOAD_PATH.unshift(File.join(File.dirname(__FILE__), '..'))
    require 'convertr'
    Convertr.configure do |c|
      c.db_config_file = 'test/database.yml'
    end
  end

  task :reset_database => :load_config do
    require 'convertr/migration'
    Convertr::Migration.down
    Convertr::Migration.up
  end

  task :load_fixtures => :load_config do
    require 'active_record/fixtures'
    Fixtures.create_fixtures(File.join(Dir.pwd, 'test', 'fixtures'), [:files, :tasks])
  end

  task :prepare_test => [:reset_database, :load_fixtures]
end
