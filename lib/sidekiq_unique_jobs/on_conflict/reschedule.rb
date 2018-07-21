# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Strategy to reschedule job on conflict
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class Reschedule < OnConflict::Strategy
      include SidekiqUniqueJobs::SidekiqWorkerMethods

      # @param [Hash] item sidekiq job hash
      def initialize(item)
        super
        @worker_class = item[CLASS_KEY]
      end

      # Create a new job from the current one.
      #   This will mess up sidekiq stats because a new job is created
      def call
        worker_class&.perform_in(5, *item[ARGS_KEY]) if sidekiq_worker_class?
      end
    end
  end
end
