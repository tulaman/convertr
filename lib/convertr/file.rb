module Convertr
  class File < ActiveRecord::Base
    set_table_name :files
    has_many :tasks, :class_name => 'Convertr::Task'
  end
end
