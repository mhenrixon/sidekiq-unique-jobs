require 'sidekiq/api'
require 'sidekiq_unique_jobs/server/extensions'

module Sidekiq
  class Job
    module UniqueExtension
      include SidekiqUniqueJobs::Server::Extensions
      def self.included(base)
        base.class_eval do
          alias_method :delete_orig, :delete
          alias_method :delete, :delete_ext
        end
      end

      def delete_ext
        unlock(payload_hash(item), item)
        delete_orig
      end

      protected

      def payload_hash(item)
        SidekiqUniqueJobs.get_payload(item['class'], item['queue'], item['args'])
      end

      def unlock(lock_key, item)
        Sidekiq.redis do |con|
          val = @parent && @parent.name == 'schedule' ? 'scheduled' : item['jid']
          con.eval(remove_on_match, keys: [lock_key], argv: [val])
        end
      end
    end
    include UniqueExtension
  end

  class Queue
    module UniqueExtension
      def self.included(base)
        base.class_eval do
          alias_method :clear_orig, :clear
          alias_method :clear, :clear_ext
        end
      end

      def clear_ext
        each(&:delete)
        clear_orig
      end
    end

    include UniqueExtension
  end

  class JobSet
    module UniqueExtension
      def self.included(base)
        base.class_eval do
          if base.method_defined?(:clear)
            alias_method :clear_orig, :clear
            alias_method :clear, :clear_ext
          end
        end
      end

      def clear_ext
        each(&:delete_ext)
        clear_orig
      end
    end

    include UniqueExtension
  end
end
