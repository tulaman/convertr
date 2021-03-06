require 'rubygems'
require 'rake'
load 'lib/tasks/convertr.rake'

begin
  require 'jeweler'
  Jeweler::Tasks.new do |gem|
    gem.name = "convertr"
    gem.summary = %Q{Useful utility for converting video files with ffmpeg}
    gem.description = %Q{Convertr works with database and handles converting tasks. It fetches files from remote sources and converts them to appropriate formats with ffmpeg}
    gem.email = "ilya.lityuga@gmail.com"
    gem.homepage = "http://github.com/tulaman/convertr"
    gem.authors = ["Ilya Lityuga", "Alexander Svetkin"]
    gem.add_development_dependency "shoulda", ">= 0"
    gem.add_development_dependency "mocha", ">= 0"
    gem.add_development_dependency "factory_girl", ">= 0"
    gem.add_dependency "activerecord", ">= 3.0.0"
    gem.requirements << "ffmpeg, any version"
    # gem is a Gem::Specification... see http://www.rubygems.org/read/chapter/20 for additional settings
  end
  Jeweler::GemcutterTasks.new
rescue LoadError
  puts "Jeweler (or a dependency) not available. Install it with: gem install jeweler"
end

require 'rake/testtask'
Rake::TestTask.new(:test) do |test|
  test.libs << 'lib' << 'test'
  test.pattern = 'test/**/test_*.rb'
  test.verbose = true
end

begin
  require 'rcov/rcovtask'
  Rcov::RcovTask.new do |test|
    test.libs << 'test'
    test.pattern = 'test/**/test_*.rb'
    test.verbose = true
    test.rcov_opts = ['-x gems']
  end
rescue LoadError
  task :rcov do
    abort "RCov is not available. In order to run rcov, you must: sudo gem install spicycode-rcov"
  end
end

task :rcov => ['convertr:prepare_test']
task :test => [:check_dependencies, 'convertr:prepare_test']

task :default => :test

require 'rake/rdoctask'
Rake::RDocTask.new do |rdoc|
  version = File.exist?('VERSION') ? File.read('VERSION') : ""

  rdoc.rdoc_dir = 'rdoc'
  rdoc.title = "convertr #{version}"
  rdoc.rdoc_files.include('README*')
  rdoc.rdoc_files.include('lib/**/*.rb')
end
