# frozen_string_literal: true

require "digest"
require "openssl"
require "sidekiq_unique_jobs/normalizer"

module SidekiqUniqueJobs
  # Handles uniqueness of sidekiq arguments
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class UniqueArgs
    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::SidekiqWorkerMethods

    # Convenience method for returning a digest
    # @param [Hash] item a Sidekiq job hash
    # @return [String] a unique digest
    def self.digest(item)
      new(item).unique_digest
    end

    # The sidekiq job hash
    # @return [Hash] the Sidekiq job hash
    attr_reader :item

    # @param [Hash] item a Sidekiq job hash
    def initialize(item)
      @item         = item
      @worker_class = item[CLASS_KEY]

      add_uniqueness_to_item
    end

    # Appends the keys unique_prefix, unique_args and {#unique_digest} to the sidekiq job hash {#item}
    # @return [void]
    def add_uniqueness_to_item
      item[UNIQUE_PREFIX_KEY] ||= unique_prefix
      item[UNIQUE_ARGS_KEY]     = unique_args(item[ARGS_KEY])
      item[UNIQUE_DIGEST_KEY]   = unique_digest
    end

    # Memoized unique_digest
    # @return [String] a unique digest
    def unique_digest
      @unique_digest ||= create_digest
    end

    # Creates a namespaced unique digest based on the {#digestable_hash} and the {#unique_prefix}
    # @return [String] a unique digest
    def create_digest
      digest = OpenSSL::Digest::MD5.hexdigest(Sidekiq.dump_json(digestable_hash))
      "#{unique_prefix}:#{digest}"
    end

    # A prefix to use as namespace for the {#unique_digest}
    # @return [String] a unique digest
    def unique_prefix
      worker_options[UNIQUE_PREFIX_KEY] || SidekiqUniqueJobs.config.unique_prefix
    end

    # Filter a hash to use for digest
    # @return [Hash] to use for digest
    def digestable_hash
      @item.slice(CLASS_KEY, QUEUE_KEY, UNIQUE_ARGS_KEY).tap do |hash|
        hash.delete(QUEUE_KEY) if unique_across_queues?
        hash.delete(CLASS_KEY) if unique_across_workers?
      end
    end

    # The unique arguments to use for creating a lock
    # @return [Array] the arguments filters by the {#filtered_args} method if {#unique_args_enabled?}
    def unique_args(args)
      return filtered_args(args) if unique_args_enabled?

      args
    end

    # Checks if we should disregard the queue when creating the unique digest
    # @return [true, false]
    def unique_across_queues?
      item[UNIQUE_ACROSS_QUEUES_KEY] || worker_options[UNIQUE_ACROSS_QUEUES_KEY] ||
        item[UNIQUE_ON_ALL_QUEUES_KEY] || worker_options[UNIQUE_ON_ALL_QUEUES_KEY] # TODO: Remove in v 6.1
    end

    # Checks if we should disregard the worker when creating the unique digest
    # @return [true, false]
    def unique_across_workers?
      item[UNIQUE_ACROSS_WORKERS_KEY] || worker_options[UNIQUE_ACROSS_WORKERS_KEY]
    end

    # Checks if the worker class has been enabled for unique_args?
    # @return [true, false]
    def unique_args_enabled?
      unique_args_method # && !unique_args_method.is_a?(Boolean)
    end

    # Filters unique arguments by proc or symbol
    # @param [Array] args the arguments passed to the sidekiq worker
    # @return [Array] {#filter_by_proc} when {#unique_args_method} is a Proc
    # @return [Array] {#filter_by_symbol} when {#unique_args_method} is a Symbol
    # @return [Array] args unfiltered when neither of the above
    def filtered_args(args)
      return args if args.empty?

      json_args = Normalizer.jsonify(args)

      case unique_args_method
      when Proc
        filter_by_proc(json_args)
      when Symbol
        filter_by_symbol(json_args)
      else
        log_debug("#{__method__} arguments not filtered (using all arguments for uniqueness)")
        json_args
      end
    end

    # Filters unique arguments by proc configured in the sidekiq worker
    # @param [Array] args the arguments passed to the sidekiq worker
    # @return [Array] with the filtered arguments
    def filter_by_proc(args)
      unique_args_method.call(args, item)
    end

    # Filters unique arguments by method configured in the sidekiq worker
    # @param [Array] args the arguments passed to the sidekiq worker
    # @return [Array] unfiltered unless {#worker_method_defined?}
    # @return [Array] with the filtered arguments
    def filter_by_symbol(args)
      return args unless worker_method_defined?(unique_args_method)

      worker_class.send(unique_args_method, args, item)
    rescue ArgumentError => ex
      log_fatal(ex)
      args
    end

    # The method to use for filtering unique arguments
    def unique_args_method
      @unique_args_method ||= worker_options[UNIQUE_ARGS_KEY]
      @unique_args_method ||= :unique_args if worker_method_defined?(:unique_args)
      @unique_args_method ||= default_unique_args_method
    end

    # The global worker options defined in Sidekiq directly
    def default_unique_args_method
      Sidekiq.default_worker_options.stringify_keys[UNIQUE_ARGS_KEY]
    end
  end
end
