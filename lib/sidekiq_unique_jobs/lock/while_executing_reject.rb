# frozen_string_literal: true

module SidekiqUniqueJobs
  class Lock
    class WhileExecutingReject < WhileExecuting
      include SidekiqUniqueJobs::Timeout
      include Sidekiq::ExceptionHandler

      def execute(callback)
        token = @locksmith.wait(@item[LOCK_TIMEOUT_KEY])
        if token
          yield if block_given?
          callback&.call
          @locksmith.signal(token)
        else
          reject!
        end
      end

      # Private below here, keeping public due to testing reasons

      def reject!
        Sidekiq.logger.debug { "Rejecting job with jid: #{item[JID_KEY]} already running" }
        send_to_deadset
      end

      def send_to_deadset
        Sidekiq.logger.info { "Adding dead #{@item[CLASS_KEY]} job #{@item[JID_KEY]}" }

        if deadset_kill?
          deadset_kill
        else
          push_to_deadset
        end
      end

      def deadset_kill?
        deadset.respond_to?(:kill)
      end

      def deadset_kill
        if kill_with_options?
          kill_job_with_options
        else
          kill_job_without_options
        end
      end

      def kill_with_options?
        Sidekiq::DeadSet.instance_method(:kill).arity > 1
      end

      def kill_job_without_options
        deadset.kill(payload) if deadset_kill?
      end

      def kill_job_with_options
        deadset.kill(payload, notify_failure: false) if deadset_kill?
      end

      def deadset
        @deadset ||= Sidekiq::DeadSet.new
      end

      def push_to_deadset
        Sidekiq.redis do |conn|
          conn.multi do
            conn.zadd('dead', current_time, payload)
            conn.zremrangebyscore('dead', '-inf', current_time - Sidekiq::DeadSet.timeout)
            conn.zremrangebyrank('dead', 0, -Sidekiq::DeadSet.max_jobs)
          end
        end
      end

      def current_time
        @current_time ||= Time.now.to_f
      end

      def payload
        @payload ||= Sidekiq.dump_json(@item)
      end
    end
  end
end
