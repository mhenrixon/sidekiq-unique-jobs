module SidekiqUniqueJobs
  class PayloadHelper
    def self.config
      SidekiqUniqueJobs.config
    end

    def self.get_payload(klass, queue, *args)
      unique_on_all_queues = false
      if config.unique_args_enabled
        worker_class = klass.constantize
        args = yield_unique_args(worker_class, *args)
        unique_on_all_queues =
          worker_class.get_sidekiq_options['unique_on_all_queues']
      end
      md5_arguments = { class: klass, args: args }
      md5_arguments[:queue] = queue unless unique_on_all_queues
      "#{config.unique_prefix}:" \
        "#{Digest::MD5.hexdigest(Sidekiq.dump_json(md5_arguments))}"
    end

    def self.yield_unique_args(worker_class, args)
      if defined?(BaseJobWrapper) && worker_class == BaseJobWrapper
        args = args.map do |arg|
          arg.is_a?(Hash) ? arg.dup.tap { |h| h.delete('job_id') } : arg
        end
      end

      unique_args = worker_class.get_sidekiq_options['unique_args']
      filtered_args(worker_class, unique_args, args)
    rescue NameError
      # fallback to not filtering args when class can't be instantiated
      args
    end

    def self.filtered_args(worker_class, unique_args, args)
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
  end
end
