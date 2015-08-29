require 'yaml' if RUBY_VERSION.include?('2.0.0') # rubocop:disable FileName
require 'sidekiq_unique_jobs/middleware'
require 'sidekiq_unique_jobs/version'
require 'sidekiq_unique_jobs/config'
require 'sidekiq_unique_jobs/sidekiq_unique_ext'

require 'ostruct'

module SidekiqUniqueJobs
  module_function

  def config
    @config ||= Config.new(
      unique_prefix: 'sidekiq_unique',
      unique_args_enabled: false,
      default_expiration: 30 * 60,
      default_unlock_order: :after_yield,
      unique_storage_method: :new,
      redis_test_mode: :redis # :mock
    )
  end

  def unique_args_enabled?
    config.unique_args_enabled
  end

  def configure
    yield config
  end

  # Attempt to constantize a string worker_class argument, always
  # failing back to the original argument.
  def worker_class_constantize(worker_class)
    return worker_class unless worker_class.is_a?(String)
    worker_class.constantize
  rescue NameError
    worker_class
  end

  def get_payload(klass, queue, *args)
    unique_on_all_queues = false
    if config.unique_args_enabled
      worker_class = worker_class_constantize(klass)
      args = yield_unique_args(worker_class, *args)
      unique_on_all_queues =
        worker_class.get_sidekiq_options['unique_on_all_queues']
    end
    md5_arguments = { class: klass, args: args }
    md5_arguments[:queue] = queue unless unique_on_all_queues
    "#{config.unique_prefix}:" \
      "#{Digest::MD5.hexdigest(Sidekiq.dump_json(md5_arguments))}"
  end

  def payload_hash(item)
    get_payload(item['class'], item['queue'], item['args'])
  end

  def yield_unique_args(worker_class, args)
    unique_args = worker_class.get_sidekiq_options['unique_args']
    filtered_args(worker_class, unique_args, args)
  rescue NameError
    # fallback to not filtering args when class can't be instantiated
    args
  end

  def connection(redis_pool = nil, &block)
    return mock_redis if SidekiqUniqueJobs.config.mocking?
    redis_pool ? redis_pool.with(&block) : Sidekiq.redis(&block)
  end

  def self.mock_redis
    @redis_mock ||= MockRedis.new
  end

  def filtered_args(worker_class, unique_args, args)
    case unique_args
    when Proc
      unique_args.call(args)
    when Symbol
      if worker_class.respond_to?(unique_args)
        worker_class.send(unique_args, *args)
      end
    else
      args
    end
  end

  def synchronize(key, redis, item = nil, &blk)
    SidekiqUniqueJobs::RunLock.synchronize(key, redis, item, &blk)
  end
end
