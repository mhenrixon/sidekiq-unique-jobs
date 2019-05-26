# frozen_string_literal: true

module SidekiqUniqueJobs
  module OnConflict
    # Strategy to send jobs to dead queue
    #
    # @author Mikael Henriksson <mikael@zoolutions.se>
    class Reject < OnConflict::Strategy
      include SidekiqUniqueJobs::Timing

      # Send jobs to dead queue
      def call
        log_debug { "Rejecting job with jid: #{item[JID]}" }
        send_to_deadset
      end

      def send_to_deadset
        log_info { "Adding dead #{item[CLASS]} job #{item[JID]}" }

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
        deadset.kill(payload)
      end

      def kill_job_with_options
        deadset.kill(payload, notify_failure: false)
      end

      def deadset
        @deadset ||= Sidekiq::DeadSet.new
      end

      def push_to_deadset
        redis do |conn|
          conn.multi do
            conn.zadd("dead", now_f, payload)
            conn.zremrangebyscore("dead", "-inf", now_f - Sidekiq::DeadSet.timeout)
            conn.zremrangebyrank("dead", 0, -Sidekiq::DeadSet.max_jobs)
          end
        end
      end

      def payload
        @payload ||= Sidekiq.dump_json(item)
      end
    end
  end
end
