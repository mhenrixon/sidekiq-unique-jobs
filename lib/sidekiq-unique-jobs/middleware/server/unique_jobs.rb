require 'digest'

module SidekiqUniqueJobs
  module Middleware
    module Server
      class UniqueJobs
        def call(*args)
          logger.info("About to process a job with args #{args.inspect}")
          yield
          logger.info("Done processing a job with args #{args.inspect}")
        ensure
          item = args[1]
          md5_arguments = {:class => item['class'], :queue => item['queue'], :args => item['args']}
          hash = Digest::MD5.hexdigest(Sidekiq.dump_json(md5_arguments))
          Sidekiq.redis {|conn| conn.del(hash) }
        end

        protected

        def logger
          Sidekiq.logger
        end
      end
    end
  end
end
