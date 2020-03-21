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
      new(item).unique_args
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
    # @return [Array] the arguments filters by the {#filtered_args} method if {#unique_args_enabled?}
    def unique_args
      @unique_args ||= filtered_args
    end

    # Checks if the worker class has enabled unique_args
    # @return [true, false]
    def unique_args_enabled?
      # return false unless unique_args_method_valid?

      unique_args_method
    end

    # Validate that the unique_args_method is acceptable
    # @return [true, false]
    def unique_args_method_valid?
      [NilClass, TrueClass, FalseClass].none? { |klass| unique_args_method.is_a?(klass) }
    end

    # Checks if the worker class has disabled unique_args
    # @return [true, false]
    def unique_args_disabled?
      !unique_args_method
    end

    # Filters unique arguments by proc or symbol
    # @param [Array] args the arguments passed to the sidekiq worker
    # @return [Array] {#filter_by_proc} when {#unique_args_method} is a Proc
    # @return [Array] {#filter_by_symbol} when {#unique_args_method} is a Symbol
    # @return [Array] args unfiltered when neither of the above
    def filtered_args
      return args if unique_args_disabled?
      return args if args.empty?

      json_args = Normalizer.jsonify(args)

      case unique_args_method
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
      unique_args_method.call(args)
    end

    # Filters unique arguments by method configured in the sidekiq worker
    # @param [Array] args the arguments passed to the sidekiq worker
    # @return [Array] unfiltered unless {#worker_method_defined?}
    # @return [Array] with the filtered arguments
    def filter_by_symbol(args)
      return args unless worker_method_defined?(unique_args_method)

      worker_class.send(unique_args_method, args)
    rescue ArgumentError
      raise SidekiqUniqueJobs::InvalidUniqueArguments,
            given: args,
            worker_class: worker_class,
            unique_args_method: unique_args_method
    end

    # The method to use for filtering unique arguments
    def unique_args_method
      @unique_args_method ||= worker_options[UNIQUE_ARGS]
      @unique_args_method ||= :unique_args if worker_method_defined?(:unique_args)
      @unique_args_method ||= default_unique_args_method
    end

    # The global worker options defined in Sidekiq directly
    def default_unique_args_method
      Sidekiq.default_worker_options.stringify_keys[UNIQUE_ARGS]
    end
  end
end
