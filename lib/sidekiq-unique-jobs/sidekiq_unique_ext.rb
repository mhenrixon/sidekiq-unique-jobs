require 'sidekiq/api'

module Sidekiq
  class Job
    module UniqueExtension
      def self.included(base)
        base.class_eval do
          alias_method :delete_orig, :delete
          alias_method :delete, :delete_ext
        end
      end

      def delete_ext
        unlock(payload_hash(self.item))
        delete_orig
      end
      protected

      def payload_hash(item)
        SidekiqUniqueJobs::PayloadHelper.get_payload(item['class'], item['queue'], item['args'])
      end

      def unlock(payload_hash)
        Sidekiq.redis { |conn| conn.del(payload_hash) }
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
        self.each { |job| job.delete }
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
        self.each { |job| job.delete_ext }
        clear_orig
      end
    end

    include UniqueExtension
  end
end
