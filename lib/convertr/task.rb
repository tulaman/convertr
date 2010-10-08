module Convertr
  class Task < ActiveRecord::Base
    set_table_name :tasks
    belongs_to :file, :class_name => 'Convertr::File'
  end
end
