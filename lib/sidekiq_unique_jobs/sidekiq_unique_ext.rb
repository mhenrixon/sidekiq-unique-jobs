require 'sidekiq/api'
require 'sidekiq_unique_jobs/server/extensions'

module Sidekiq
  class SortedEntry
    module UniqueExtension
      include SidekiqUniqueJobs::Server::Extensions

      def self.included(base)
        base.class_eval do
          alias_method :delete_orig, :delete
          alias_method :delete, :delete_ext
          alias_method :remove_job_orig, :remove_job
          alias_method :remove_job, :remove_job_ext
        end
      end

      def delete_ext
        unlock(payload_hash(item), item)
        delete_orig
      end

      def remove_job_ext
        remove_job_orig do |message|
          unlock(payload_hash(Sidekiq.load_json(message)), item)
          yield message
        end
      end
    end

    include UniqueExtension if Gem::Version.new(Sidekiq::VERSION) >= Gem::Version.new('3.1')
  end

  class Job
    module UniqueExtension
      SCHEDULED ||= 'schedule'.freeze
      include SidekiqUniqueJobs::Server::Extensions
      extend Forwardable
      def_delegator :SidekiqUniqueJobs, :payload_hash

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

      def unlock(lock_key, item)
        Sidekiq.redis do |con|
          con.eval(remove_on_match, keys: [lock_key], argv: [item['jid']])
          if defined?(@parent) && @parent && @parent.name == SCHEDULED
            con.eval(remove_scheduled_on_match, keys: [lock_key], argv: [item['jid']])
          else
            con.eval(remove_on_match, keys: [lock_key], argv: [item['jid']])
          end
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
