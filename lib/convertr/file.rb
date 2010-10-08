module Convertr
  class File < ActiveRecord::Base
    set_table_name :files
    has_many :tasks, :class_name => 'Convertr::Task'
    scope :without_convertor, where('convertor is null').order('broadcast_at asc')
    scope :with_convertor, lambda { |convertor|
      where(:convertor => convertor).order('broadcast_at asc')
    }
  end
end
