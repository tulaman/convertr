module Convertr
  module Version
    class << self
      def to_s
        File.read( File.join(File.dirname(__FILE__), '..', 'VERSION') ).chomp
      end
    end
  end
end
