# frozen_string_literal: true

# :nocov:
# :nodoc:

require "sidekiq"
require "sidekiq/testing"

#
# See Sidekiq gem for more details
#
module Sidekiq
  #
  # Temporarily turn Sidekiq's options into something different
  #
  # @note this method will restore the original options after yielding
  #
  # @param [Hash<Symbol, Object>] tmp_config the temporary config to use
  #
  def self.use_options(tmp_config = {})
    old_config = default_worker_options
    default_worker_options.clear
    self.default_worker_options = tmp_config

    yield
  ensure
    default_worker_options.clear
    self.default_worker_options = old_config
  end

  #
  # See Sidekiq::Worker in Sidekiq gem for more details
  #
  module Worker
    #
    # Adds class methods to Sidekiq::Worker
    #
    module ClassMethods
      #
      # Temporarily turn a workers sidekiq_options into something different
      #
      # @note this method will restore the original configuration after yielding
      #
      # @param [Hash<Symbol, Object>] tmp_config the temporary config to use
      #
      def use_options(tmp_config = {})
        old_config = get_sidekiq_options
        sidekiq_options(tmp_config)

        yield
      ensure
        self.sidekiq_options_hash = Sidekiq.default_worker_options
        sidekiq_options(old_config)
      end

      #
      # Clears the jobs for this worker and removes all locks
      #
      def clear
        jobs.each do |job|
          SidekiqUniqueJobs::Unlockable.unlock(job)
        end

        Sidekiq::Queues[queue].clear
        jobs.clear
      end
    end

    #
    # Prepends deletion of locks to clear_all
    #
    module Overrides
      #
      # Clears all jobs for this worker and removes all locks
      #
      def clear_all
        super
        SidekiqUniqueJobs::Digests.new.del(pattern: "*", count: 1_000)
      end
    end

    prepend Overrides
  end
end
