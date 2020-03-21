# frozen_string_literal: true

module SidekiqUniqueJobs
  # Handles uniqueness of sidekiq arguments
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class LockDigest
    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::JSON
    include SidekiqUniqueJobs::SidekiqWorkerMethods

    def self.call(item)
      new(item).unique_digest
    end

    # The sidekiq job hash
    # @return [Hash] the Sidekiq job hash
    attr_reader :item
    #
    # @!attribute [r] args
    #   @return [Array<Objet>] the arguments passed to `perform_async`
    attr_reader :unique_args
    #
    # @!attribute [r] args
    #   @return [String] the prefix for the unique key
    attr_reader :unique_prefix

    # @param [Hash] item a Sidekiq job hash
    def initialize(item)
      @item          = item
      @worker_class  = item[CLASS]
      @unique_args   = item[UNIQUE_ARGS]
      @unique_prefix = item[UNIQUE_PREFIX]
    end

    # Memoized unique_digest
    # @return [String] a unique digest
    def unique_digest
      @unique_digest ||= create_digest
    end

    # Creates a namespaced unique digest based on the {#digestable_hash} and the {#unique_prefix}
    # @return [String] a unique digest
    def create_digest
      digest = ::Digest::MD5.hexdigest(dump_json(digestable_hash))
      "#{unique_prefix}:#{digest}"
    end

    # Filter a hash to use for digest
    # @return [Hash] to use for digest
    def digestable_hash
      @item.slice(CLASS, QUEUE, UNIQUE_ARGS).tap do |hash|
        hash.delete(QUEUE) if unique_across_queues?
        hash.delete(CLASS) if unique_across_workers?
      end
    end

    # Checks if we should disregard the queue when creating the unique digest
    # @return [true, false]
    def unique_across_queues?
      item[UNIQUE_ACROSS_QUEUES] || worker_options[UNIQUE_ACROSS_QUEUES]
    end

    # Checks if we should disregard the worker when creating the unique digest
    # @return [true, false]
    def unique_across_workers?
      item[UNIQUE_ACROSS_WORKERS] || worker_options[UNIQUE_ACROSS_WORKERS]
    end
  end
end
