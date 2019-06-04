module SidekiqUniqueJobs
  class Lock
    class ClientValidator
      INVALID_ON_CLIENT_CONFLICTS = %i[
        raise
        reject
        reschedule
      ]

      def validate
        on_server_conflict = config.on_server_conflict
        if INVALID_ON_CLIENT_CONFLICTS.include?(on_server_conflict)
          options[:errors][:on_server_conflict] = "#{on_server_conflict} is incompatible with the server process"
        end
      end
    end
  end
end
