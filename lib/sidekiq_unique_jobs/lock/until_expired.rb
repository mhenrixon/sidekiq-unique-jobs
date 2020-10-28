# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    #
    # UntilExpired locks until the job expires
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    #
    class UntilExpired < UntilExecuted
    end
  end
end
