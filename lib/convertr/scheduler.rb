module Convertr
  module Scheduler
    class Base
      def initialize
      end

      def schedule_next_task(convertor)
        # TODO: locking
        if task = get_task_for_schedule(convertor)
          schedule(task, convertor)
        end
        task
      end

      private

      def get_task_for_schedule(convertor) # abstract
        raise "Should be overriden"
      end

      def schedule(task, convertor)
        Convertr::Task.transaction do
          task.update_attributes(:convert_status => 'PROGRESS', :convert_started_at => Time.now)
          task.file.update_attribute(:convertor => convertor)
        end
      end
    end
  end
end
