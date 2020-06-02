# frozen_string_literal: true

module SidekiqUniqueJobs
  # Handles uniqueness of sidekiq arguments
  #
  # @author Mikael Henriksson <mikael@zoolutions.se>
  class LockArgs
    include SidekiqUniqueJobs::Logging
    include SidekiqUniqueJobs::SidekiqWorkerMethods
    include SidekiqUniqueJobs::JSON

    # Convenience method for returning a digest
    # @param [Hash] item a Sidekiq job hash
    # @return [String] a unique digest
    def self.call(item)
      new(item).lock_args
    end

    # The sidekiq job hash
    # @return [Hash] the Sidekiq job hash
    attr_reader :item
    #
    # @!attribute [r] args
    #   @return [Array<Objet>] the arguments passed to `perform_async`
    attr_reader :args

    # @param [Hash] item a Sidekiq job hash
    def initialize(item)
      @item         = item
      @worker_class = item[CLASS]
      @args         = item[ARGS]
    end

    # The unique arguments to use for creating a lock
    # @return [Array] the arguments filters by the {#filtered_args} method if {#lock_args_enabled?}
    def lock_args
      @lock_args ||= filtered_args
    end

    # Checks if the worker class has enabled lock_args
    # @return [true, false]
    def lock_args_enabled?
      # return false unless lock_args_method_valid?

      lock_args_method
    end

    # Validate that the lock_args_method is acceptable
    # @return [true, false]
    def lock_args_method_valid?
      [NilClass, TrueClass, FalseClass].none? { |klass| lock_args_method.is_a?(klass) }
    end

    # Checks if the worker class has disabled lock_args
    # @return [true, false]
    def lock_args_disabled?
      !lock_args_method
    end

    # Filters unique arguments by proc or symbol
    # @return [Array] {#filter_by_proc} when {#lock_args_method} is a Proc
    # @return [Array] {#filter_by_symbol} when {#lock_args_method} is a Symbol
    # @return [Array] args unfiltered when neither of the above
    def filtered_args
      return args if lock_args_disabled?

      json_args = Normalizer.jsonify(args)

      case lock_args_method
      when Proc
        filter_by_proc(json_args)
      when Symbol
        filter_by_symbol(json_args)
      end
    end

    # Filters unique arguments by proc configured in the sidekiq worker
    # @param [Array] args the arguments passed to the sidekiq worker
    # @return [Array] with the filtered arguments
    def filter_by_proc(args)
      lock_args_method.call(args)
    end

    # Filters unique arguments by method configured in the sidekiq worker
    # @param [Array] args the arguments passed to the sidekiq worker
    # @return [Array] unfiltered unless {#worker_method_defined?}
    # @return [Array] with the filtered arguments
    def filter_by_symbol(args)
      return args unless worker_method_defined?(lock_args_method)

      worker_class.send(lock_args_method, args)
    rescue ArgumentError
      raise SidekiqUniqueJobs::InvalidUniqueArguments,
            given: args,
            worker_class: worker_class,
            lock_args_method: lock_args_method
    end

    # The method to use for filtering unique arguments
    def lock_args_method
      @lock_args_method ||= worker_options[LOCK_ARGS] || worker_options[UNIQUE_ARGS]
      @lock_args_method ||= :lock_args if worker_method_defined?(:lock_args)
      @lock_args_method ||= :unique_args if worker_method_defined?(:unique_args)
      @lock_args_method ||= default_lock_args_method
    end

    # The global worker options defined in Sidekiq directly
    def default_lock_args_method
      default_worker_options[LOCK_ARGS] ||
        default_worker_options[UNIQUE_ARGS]
    end

    #
    # The globally default worker options configured from Sidekiq
    #
    #
    # @return [Hash<String, Object>]
    #
    def default_worker_options
      @default_worker_options ||= Sidekiq.default_worker_options.stringify_keys
    end
  end
end
