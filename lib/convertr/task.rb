module Convertr
  class Task < ActiveRecord::Base
    set_table_name :tasks
    belongs_to :file, :class_name => 'Convertr::File'
    scope :not_completed, where(:convert_status => 'NONE')
    scope :for_convertor, lambda { |convertor|
      not_completed.includes(:file).where('files.convertor' => convertor).order('files.broadcast_at asc')
    }
    scope :without_convertor, not_completed.includes(:file).where('files.convertor is null').order('files.broadcast_at asc')
  end
end
