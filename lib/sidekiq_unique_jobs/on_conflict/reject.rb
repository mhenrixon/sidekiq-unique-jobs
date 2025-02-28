# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Strategy to send jobs to dead queue
    #
    # @author Mikael Henriksson <mikael@mhenrixon.com>
    class Reject < OnConflict::Strategy
      include SidekiqUniqueJobs::Timing

      # Send jobs to dead queue
      def call
        log_info { "Adding dead #{item[CLASS]} job #{item[JID]}" }

        if kill_with_options?
          kill_job_with_options
        else
          kill_job_without_options
        end
      end

      #
      # Sidekiq version compatibility check
      # @api private
      #
      #
      # @return [true] when Sidekiq::Deadset#kill takes more than 1 argument
      # @return [false] when Sidekiq::Deadset#kill does not take multiple arguments
      #
      def kill_with_options?
        kill_arity = Sidekiq::DeadSet.instance_method(:kill).arity
        # Method#arity returns:
        #   1. a nonnegative number for methods that take a fixed number of arguments.
        #   2. A negative number if it takes a variable number of arguments.
        # Keyword arguments are considered a single argument, and are considered optional unless one of the kwargs is
        # required.
        # Therefore, to determine if `Sidekiq::DeadSet#kill` accepts options beyond the single positional payload
        # argument, we need to check whether the absolute value of the arity is greater than 1.
        # See: https://apidock.com/ruby/Method/arity
        kill_arity > 1 || kill_arity < -1
      end

      #
      # Executes the kill instructions without arguments
      # @api private
      #
      # @return [void]
      #
      def kill_job_without_options
        deadset.kill(payload)
      end

      #
      # Executes the kill instructions with arguments
      # @api private
      #
      # @return [void]
      #
      def kill_job_with_options
        deadset.kill(payload, notify_failure: false)
      end

      #
      # An instance of Sidekiq::Deadset
      # @api private
      #
      # @return [Sidekiq::Deadset]>
      #
      def deadset
        @deadset ||= Sidekiq::DeadSet.new
      end

      #
      # The Sidekiq job hash as JSON
      #
      #
      # @return [String] a JSON formatted string
      #
      def payload
        @payload ||= dump_json(item)
      end
    end
  end
end
