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
end
