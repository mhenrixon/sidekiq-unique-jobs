# frozen_string_literal: true

require 'digest'
require 'sidekiq_unique_jobs/normalizer'

module SidekiqUniqueJobs
  # This class exists to be testable and the entire api should be considered private
  class UniqueArgs
    CLASS_NAME = 'SidekiqUniqueJobs::UniqueArgs'

    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::SidekiqWorkerMethods

    def self.digest(item)
      new(item).unique_digest
    end

    attr_reader :item

    def initialize(item)
      @item         = item
      @worker_class = item[CLASS_KEY]

      add_uniqueness_to_item
    end

    def add_uniqueness_to_item
      item[UNIQUE_PREFIX_KEY] ||= unique_prefix
      item[UNIQUE_ARGS_KEY]     = unique_args(item[ARGS_KEY])
      item[UNIQUE_DIGEST_KEY]   = unique_digest
    end

    def unique_digest
      @unique_digest ||= create_digest
    end

    def create_digest
      digest = Digest::MD5.hexdigest(Sidekiq.dump_json(digestable_hash))
      "#{unique_prefix}:#{digest}"
    end

    def unique_prefix
      worker_options[UNIQUE_PREFIX_KEY] || SidekiqUniqueJobs.config.unique_prefix
    end

    def digestable_hash
      @item.slice(CLASS_KEY, QUEUE_KEY, UNIQUE_ARGS_KEY).tap do |hash|
        hash.delete(QUEUE_KEY) if unique_on_all_queues?
        hash.delete(CLASS_KEY) if unique_across_workers?
      end
    end

    def unique_args(args)
      return filtered_args(args) if unique_args_enabled?
      args
    end

    def unique_on_all_queues?
      item[UNIQUE_ON_ALL_QUEUES_KEY] || worker_options[UNIQUE_ON_ALL_QUEUES_KEY]
    end

    def unique_across_workers?
      item[UNIQUE_ACROSS_WORKERS_KEY] || worker_options[UNIQUE_ACROSS_WORKERS_KEY]
    end

    def unique_args_enabled?
      unique_args_method # && !unique_args_method.is_a?(Boolean)
    end

    # Filters unique arguments by proc or symbol
    # returns provided arguments for other configurations
    def filtered_args(args)
      return args if args.empty?
      json_args = Normalizer.jsonify(args)

      case unique_args_method
      when Proc
        filter_by_proc(json_args)
      when Symbol
        filter_by_symbol(json_args)
      else
        log_debug { "#{__method__} arguments not filtered (using all arguments for uniqueness)" }
        json_args
      end
    end

    def filter_by_proc(args)
      return args if unique_args_method.nil?

      unique_args_method.call(args)
    end

    def filter_by_symbol(args)
      return args unless worker_method_defined?(unique_args_method)

      worker_class.send(unique_args_method, args)
    rescue ArgumentError => ex
      log_fatal ex
      args
    end

    def unique_args_method
      @unique_args_method ||= worker_options[UNIQUE_ARGS_KEY]
      @unique_args_method ||= :unique_args if worker_method_defined?(:unique_args)
      @unique_args_method ||= Sidekiq.default_worker_options.stringify_keys[UNIQUE_ARGS_KEY]
    end
  end
end
