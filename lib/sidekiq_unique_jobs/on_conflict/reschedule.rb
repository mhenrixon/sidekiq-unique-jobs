# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Strategy to reschedule job on conflict
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Reschedule < OnConflict::Strategy
      include SidekiqUniqueJobs::SidekiqWorkerMethods
      include SidekiqUniqueJobs::Logging
      include SidekiqUniqueJobs::JSON
      include SidekiqUniqueJobs::Reflectable

      # @param [Hash] item sidekiq job hash
      def initialize(item, redis_pool = nil)
        super
        self.job_class = item[CLASS]
      end

      # Create a new job from the current one.
      #   Sets the RESCHEDULED flag so the middleware skips uniqueness checks,
      #   avoiding infinite recursion when the lock is still held.
      def call
        if sidekiq_job_class?
          jid = job_class
            .set(queue: item[QUEUE].to_sym, RESCHEDULED => true)
            .perform_in(schedule_in, *item[ARGS])

          if jid
            reflect(:rescheduled, item)
          else
            reflect(:reschedule_failed, item)
          end
        else
          reflect(:unknown_sidekiq_worker, item)
        end
      end

      def schedule_in
        job_class.get_sidekiq_options["schedule_in"] || 5
      end
    end
  end
end
