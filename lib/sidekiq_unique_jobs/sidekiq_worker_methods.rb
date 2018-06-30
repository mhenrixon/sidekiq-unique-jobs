# frozen_string_literal: true

module SidekiqUniqueJobs
  module SidekiqWorkerMethods
    def worker_method_defined?(method_sym)
      worker_class.respond_to?(method_sym)
    end

    def worker_options
      return {} unless sidekiq_worker_class?
      worker_class.get_sidekiq_options.stringify_keys
    end

    def sidekiq_worker_class?
      worker_method_defined?(:get_sidekiq_options)
    end

    def worker_class
      @_worker_class ||= worker_class_constantize # rubocop:disable Naming/MemoizedInstanceVariableName
    end

    def after_unlock_hook
      -> { worker_class.after_unlock if worker_method_defined?(:after_unlock) }
    end

    # Attempt to constantize a string worker_class argument, always
    # failing back to the original argument when the constant can't be found
    #
    # raises an error for other errors
    def worker_class_constantize(klazz = @worker_class)
      return klazz unless klazz.is_a?(String)
      Object.const_get(klazz)
    rescue NameError => ex
      case ex.message
      when /uninitialized constant/
        klazz
      else
        raise
      end
    end

    def default_worker_options
      Sidekiq.default_worker_options
    end
  end
end
