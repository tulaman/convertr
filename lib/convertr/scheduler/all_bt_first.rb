module Convertr
  module Scheduler
    class AllBtFirst < Base
      def get_task_for_schedule(convertor)
        Convertr::Task.for_convertor(convertor).first ||
        Convertr::Task.without_convertor.first
      end
    end
  end
end
