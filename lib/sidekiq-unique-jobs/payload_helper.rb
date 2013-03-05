module SidekiqUniqueJobs
  class PayloadHelper
    def self.get_payload(klass, queue, *args)
      args = yield_unique_args(klass, *args) if SidekiqUniqueJobs::Config.unique_args_enabled?
      md5_arguments = {:class => klass, :queue => queue, :args => args}
      "#{SidekiqUniqueJobs::Config.unique_prefix}:#{Digest::MD5.hexdigest(Sidekiq.dump_json(md5_arguments))}"
    end

    def self.yield_unique_args(klass, args)
      worker_class = klass.constantize
      unique_args = worker_class.get_sidekiq_options['unique_args']
      filtered_args = if unique_args
                        case unique_args
                          when Proc
                            unique_args.call(args)
                          when Symbol
                            worker_class.send(unique_args, *args) if worker_class.respond_to?(unique_args)
                        end
                      end
      filtered_args || args
    rescue NameError # if we can't instantiate the class, we just fallback to not filtering args
      args
    end
  end
end
