# frozen_string_literal: true

class LocksController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:enqueue, :flush]

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
    job_class = job_name.safe_constantize

    unless job_class
      redirect_to locks_path, alert: "Unknown job: #{job_name}"
      return
    end

    args = DEMO_JOBS.dig(job_name, :sample_args) || []
    results = []

    count.times do
      jid = if args.any?
        job_class.perform_async(*args)
      else
        job_class.perform_async
      end
      results << jid
    end

    successful = results.compact.size
    redirect_to locks_path,
      notice: "Enqueued #{successful}/#{count} #{job_name} jobs"
  end

  def flush
    SidekiqUniqueJobs::Digests.new.delete_by_pattern("*")
    redirect_to locks_path, notice: "All lock digests flushed"
  end

  private

  def fetch_digests
    digests = SidekiqUniqueJobs::Digests.new
    entries = digests.entries(pattern: "*", count: 100)
    entries.map do |digest|
      info = lock_info_for(digest)
      { digest: digest, info: info }
    end
  rescue => e
    Rails.logger.error("Failed to fetch digests: #{e.message}")
    []
  end

  def fetch_digests_for_job(job_name)
    digests = SidekiqUniqueJobs::Digests.new
    entries = digests.entries(pattern: "*#{job_name}*", count: 100)
    entries.map do |digest|
      info = lock_info_for(digest)
      key = SidekiqUniqueJobs::Key.new(digest)
      lock_state = fetch_lock_state(key)
      { digest: digest, info: info, key: key, state: lock_state }
    end
  rescue => e
    Rails.logger.error("Failed to fetch digests for #{job_name}: #{e.message}")
    []
  end

  def lock_info_for(digest)
    key = SidekiqUniqueJobs::Key.new(digest)
    info_json = redis { |conn| conn.get(key.info) }
    return {} unless info_json

    JSON.parse(info_json)
  rescue JSON::ParserError
    {}
  end

  def fetch_lock_state(key)
    redis do |conn|
      {
        queued: conn.llen(key.queued),
        primed: conn.llen(key.primed),
        locked: conn.hgetall(key.locked),
        pttl: conn.pttl(key.digest),
      }
    end
  rescue => e
    Rails.logger.error("Failed to fetch lock state: #{e.message}")
    { queued: 0, primed: 0, locked: {}, pttl: -2 }
  end

  def fetch_queue_stats
    Sidekiq::Stats.new
  rescue => e
    Rails.logger.error("Failed to fetch queue stats: #{e.message}")
    nil
  end

  def redis(&block)
    Sidekiq.redis(&block)
  end

  def render_not_found
    render plain: "Not found", status: :not_found
  end
end
