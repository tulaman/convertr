module Convertr
  class File < ActiveRecord::Base
    set_table_name :files
    has_many :tasks, :class_name => 'Convertr::Task'
    scope :without_convertor, where('convertor is null').order('broadcast_at asc')
    scope :with_convertor, lambda { |convertor|
      where(:convertor => convertor).order('broadcast_at asc')
    }

    def float_aspect
      (w, h) = aspect.split(':')
      w.to_f / h.to_f
    end
  end
end
