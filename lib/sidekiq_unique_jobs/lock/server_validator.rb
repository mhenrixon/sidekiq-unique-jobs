module SidekiqUniqueJobs
  class Lock
    class ServerValidator < Validator
      INVALID_ON_SERVER_CONFLICTS = %i[
        replace
      ]

      def validate
        on_server_conflict = config.on_server_conflict
        if INVALID_ON_SERVER_CONFLICTS.include?(on_server_conflict)
          options[:errors][:on_server_conflict] = "#{on_server_conflict} is incompatible with the server process"
        end
      end
    end
  end
end
