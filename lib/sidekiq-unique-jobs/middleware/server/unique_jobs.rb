require 'digest'

module SidekiqUniqueJobs
  module Middleware
    module Server
      class UniqueJobs
        def call(*args)
          yield
        ensure
          item = args[1]
          payload_hash = SidekiqUniqueJobs::PayloadHelper.get_payload(item['class'], item['queue'], item['args'])

          Sidekiq.redis {|conn| conn.del(payload_hash) }
        end

        protected

        def logger
          Sidekiq.logger
        end
      end
    end
  end
end
