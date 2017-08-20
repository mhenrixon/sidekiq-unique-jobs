# frozen_string_literal: true

require 'sidekiq_unique_jobs/testing/sidekiq_overrides'

module SidekiqUniqueJobs
  alias redis_version_real redis_version
  def redis_version
    if mocked?
      '0.0'
    else
      redis_version_real
    end
  end

  class Lock
    module Testing
      def self.included(base)
        base.class_eval do
          alias_method :exists_or_create_orig!, :exists_or_create!
          alias_method :exists_or_create!, :exists_or_create_ext!

          alias_method :lock_orig, :lock
          alias_method :lock, :lock_ext
        end
      end

      def exists_or_create_ext! # rubocop:disable Metrics/MethodLength
        return exists_or_create_orig! unless SidekiqUniqueJobs.mocked?

        SidekiqUniqueJobs.connection do |conn|
          current_token = conn.getset(exists_key, @current_jid)

          if current_token.nil?
            conn.expire(exists_key, 10)

            conn.multi do
              conn.del(grabbed_key)
              conn.del(available_key)
              conn.rpush(available_key, @current_jid)
              conn.persist(exists_key)

              expire_when_necessary(conn)
            end

            @current_jid
          else
            current_token
          end
        end
      end

      def lock_ext(timeout = nil) # rubocop:disable Metrics/LineLength, Metrics/MethodLength, Metrics/PerceivedComplexity, Metrics/CyclomaticComplexity
        unless SidekiqUniqueJobs.mocked?
          return lock_orig(timeout) unless block_given?
          return lock_orig(timeout) do |_token|
            yield
          end
        end

        SidekiqUniqueJobs.connection(@redis_pool) do |conn|
          exists_or_create_ext!
          release_stale_locks!

          if timeout.nil? || timeout.positive?
            # passing timeout 0 to blpop causes it to block
            _key, current_token = conn.blpop(available_key, timeout || 0)
          else
            current_token = conn.lpop(available_key)
          end

          return false if current_token != @current_jid

          conn.hset(grabbed_key, current_token, current_time.to_f)
          return_value = current_token

          if block_given?
            begin
              return_value = yield current_token
            ensure
              signal(conn, current_token)
            end
          end

          return_value
        end
      end
    end

    include Testing
  end

  module Client
    class Middleware
      alias call_real call
      def call(worker_class, item, queue, redis_pool = nil)
        worker_class = SidekiqUniqueJobs.worker_class_constantize(worker_class)
        if Sidekiq::Testing.inline?
          call_real(worker_class, item, queue, redis_pool) do
            server_middleware.call(worker_class.new, item, queue, redis_pool) do
              yield
            end
          end
        else
          call_real(worker_class, item, queue, redis_pool) do
            yield
          end
        end
      end

      def server_middleware
        SidekiqUniqueJobs::Server::Middleware.new
      end
    end
  end
end
