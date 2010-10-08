module Convertr
  module Scheduler
    class AllBtFirst < Base
      def get_task_for_schedule(convertor)
        Convertr::Task.for_convertor(convertor).first# ||
#        Convertr::File.without_convertor.select {|f| !f.tasks.empty?}.tasks.first
      end
    end
  end
end
