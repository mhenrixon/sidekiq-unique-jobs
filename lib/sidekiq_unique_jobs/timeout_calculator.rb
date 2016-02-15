module SidekiqUniqueJobs
  module TimeoutCalculator
    def time_until_scheduled
      scheduled = item[AT_KEY]
      return 0 unless scheduled
      (Time.at(scheduled) - Time.now.utc).to_i
    end

    def seconds
      raise NotImplementedError
    end

    def worker_class_queue_lock_expiration
      worker_class_expiration_for QUEUE_LOCK_TIMEOUT_KEY
    end

    def worker_class_run_lock_expiration
      worker_class_expiration_for RUN_LOCK_TIMEOUT_KEY
    end

    def worker_class
      @worker_class ||= SidekiqUniqueJobs.worker_class_constantize(item[CLASS_KEY])
    end

    private

    def worker_class_expiration_for(key)
      return unless worker_class.respond_to?(:get_sidekiq_options)
      worker_class.get_sidekiq_options[key]
    end

    attr_reader :item
  end
end
