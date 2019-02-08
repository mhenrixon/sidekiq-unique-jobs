# frozen_string_literal: true

# :nocov:

require "sidekiq"
require "sidekiq/testing"

module Sidekiq
  def self.use_options(tmp_config = {})
    old_config = default_worker_options
    default_worker_options.clear
    self.default_worker_options = tmp_config

    yield
  ensure
    default_worker_options.clear
    self.default_worker_options = old_config
  end

  module Worker
    module ClassMethods
      def use_options(tmp_config = {})
        old_config = get_sidekiq_options
        sidekiq_options(tmp_config)

        yield
      ensure
        sidekiq_options(old_config)
      end

      def clear
        jobs.each do |job|
          SidekiqUniqueJobs::Unlockable.delete(job)
        end

        Sidekiq::Queues[queue].clear
        jobs.clear
      end
    end

    module Overrides
      def self.included(base)
        base.extend Testing
        base.class_eval do
          class << self
            alias_method :clear_all_orig, :clear_all
            alias_method :clear_all, :clear_all_ext
          end
        end
      end

      module Testing
        def clear_all_ext
          clear_all_orig
          SidekiqUniqueJobs::Util.del("*", 1000)
        end
      end
    end

    include Overrides
  end
end
