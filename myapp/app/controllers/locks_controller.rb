# frozen_string_literal: true

class LocksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:enqueue, :flush, :load_test]

  DEMO_JOBS = {
    "MyJob" => {
      description: "until_and_while_executing lock with args",
      lock_type: :until_and_while_executing,
      sample_args: ["test-id-123"],
    },
    "UntilExecutedJob" => {
      description: "until_executed lock, no args",
      lock_type: :until_executed,
      sample_args: [],
    },
    "UntilExecutingJob" => {
      description: "until_executing lock",
      lock_type: :until_executing,
      sample_args: [],
    },
    "UntilExpiredJob" => {
      description: "until_expired with TTL 24h, limit 3",
      lock_type: :until_expired,
      sample_args: [],
    },
    "WhileBusyJob" => {
      description: "while_executing with reschedule on conflict",
      lock_type: :while_executing,
      sample_args: [],
    },
    "WhileEnqueuedAndBusyJob" => {
      description: "until_and_while_executing, limit 4, log on conflict",
      lock_type: :until_and_while_executing,
      sample_args: [],
    },
    "UntilExecutedWithLockArgsJob" => {
      description: "until_executed with custom lock_args, limit 2",
      lock_type: :until_executed,
      sample_args: ["arg1", { "bogus" => "val" }],
    },
    "StatusJob" => {
      description: "until_executed, accepts args",
      lock_type: :until_executed,
      sample_args: ["status-check"],
    },
    "CronJob" => {
      description: "until_executed, timeout 0, reschedule on conflict",
      lock_type: :until_executed,
      sample_args: [],
    },
  }.freeze

  def index
    render Locks::IndexView.new(
      jobs: DEMO_JOBS,
      digests: fetch_digests,
      queue_stats: fetch_queue_stats,
      reaper_config: reaper_config,
    )
  end

  def show
    job_name = params[:id]
    job_info = DEMO_JOBS[job_name]
    return render_not_found unless job_info

    render Locks::ShowView.new(
      job_name: job_name,
      job_info: job_info,
      lock_digests: fetch_digests_for_job(job_name),
    )
  end

  def enqueue
    job_name = params[:job_name]
    count = (params[:count] || 1).to_i.clamp(1, 10)

    unless DEMO_JOBS.key?(job_name)
      redirect_to locks_path, alert: "Unknown job: #{job_name}"
      return
    end

    job_class = job_name.constantize
    args = DEMO_JOBS.dig(job_name, :sample_args) || []
    results = []

    count.times do
      jid = if args.any?
        job_class.perform_async(*args)
      else
        job_class.perform_async
      end
      results << jid
    rescue SystemStackError
      results << nil
    end

    successful = results.compact.size
    rejected = results.size - successful
    msg = "Enqueued #{successful}/#{count} #{job_name} jobs"
    msg += " (#{rejected} rejected by lock)" if rejected.positive?
    redirect_to locks_path, notice: msg
  end

  def load_test
    count = (params[:count] || 50).to_i.clamp(1, 2_000)

    Thread.new do
      enqueued = 0
      rejected = 0

      count.times do
        job_name, info = DEMO_JOBS.to_a.sample
        job_class = job_name.constantize
        args = randomize_args(info[:sample_args] || [])

        jid = args.any? ? job_class.perform_async(*args) : job_class.perform_async
        jid ? (enqueued += 1) : (rejected += 1)
      rescue StandardError => e
        Rails.logger.warn("Load test enqueue failed: #{e.class}: #{e.message}")
        rejected += 1
      end

      Rails.logger.info("Load test complete: #{enqueued} enqueued, #{rejected} rejected out of #{count}")
    end

    redirect_to locks_path, notice: "Load test started: firing #{count} random jobs in background"
  end

  def flush
    SidekiqUniqueJobs::Digests.new.delete_by_pattern("*")
    redirect_to locks_path, notice: "All lock digests flushed"
  end

  private

  def fetch_digests
    digests = SidekiqUniqueJobs::Digests.new
    entries = digests.entries(pattern: "*", count: 100)
    entries.map do |digest_str, _score|
      lock = SidekiqUniqueJobs::Lock.new(digest_str)
      info = lock.info
      {
        digest: digest_str,
        info: {
          "worker" => info["worker"],
          "type" => info["type"],
          "queue" => info["queue"],
        },
      }
    end
  rescue StandardError => e
    Rails.logger.error("Failed to fetch digests: #{e.message}")
    []
  end

  def fetch_digests_for_job(job_name)
    digests = SidekiqUniqueJobs::Digests.new
    all_entries = digests.entries(pattern: "*", count: 500)
    all_entries.filter_map do |digest_str, _score|
      lock = SidekiqUniqueJobs::Lock.new(digest_str)
      info = lock.info
      next unless info["worker"] == job_name

      jids = lock.locked_jids
      pttl = redis { |conn| conn.call("PTTL", "#{digest_str}:LOCKED") }
      {
        digest: digest_str,
        info: info.value,
        locked_jids: jids,
        pttl: pttl,
      }
    end
  rescue StandardError => e
    Rails.logger.error("Failed to fetch digests for #{job_name}: #{e.message}")
    []
  end

  def fetch_queue_stats
    Sidekiq::Stats.new
  rescue StandardError => e
    Rails.logger.error("Failed to fetch queue stats: #{e.message}")
    nil
  end

  def reaper_config
    config = SidekiqUniqueJobs.config
    {
      reaper: config.reaper,
      interval: config.reaper_interval,
      timeout: config.reaper_timeout,
      count: config.reaper_count,
    }
  end

  # Randomize args so each enqueue produces a different lock digest,
  # exercising the lock lifecycle more realistically under load.
  def randomize_args(sample_args)
    return [] if sample_args.empty?

    sample_args.map do |arg|
      case arg
      when String then "#{arg}-#{SecureRandom.hex(4)}"
      when Hash then arg.transform_values { |v| "#{v}-#{SecureRandom.hex(4)}" }
      else arg
      end
    end
  end

  def redis(&block)
    Sidekiq.redis(&block)
  end

  def render_not_found
    render plain: "Not found", status: :not_found
  end
end
