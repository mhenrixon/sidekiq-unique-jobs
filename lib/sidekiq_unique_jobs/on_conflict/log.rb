# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Strategy to log information about conflict
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class Log < OnConflict::Strategy
      include SidekiqUniqueJobs::Logging

      # Logs an informational message about that the job was not unique
      def call
        log_info(
          "skipping job with id (#{item[JID_KEY]}) " \
          "because unique_digest: (#{item[UNIQUE_DIGEST_KEY]}) already exists",
        )
      end
    end
  end
end
