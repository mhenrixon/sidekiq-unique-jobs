# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Strategy to log information about conflict
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Log < OnConflict::Strategy
      include SidekiqUniqueJobs::Logging

      #
      # Logs an informational message about that the job was not unique
      #
      #
      # @return [nil]
      #
      def call
        log_info(<<~MESSAGE.chomp)
          Skipping job with id (#{item[JID]}) because lock_digest: (#{item[LOCK_DIGEST]}) already exists
        MESSAGE
        nil
      end
    end
  end
end
