module SidekiqUniqueJobs
  class PayloadHelper
    def self.get_payload(klass, queue, *args)
      md5_arguments = {:class => klass, :queue => queue, :args => args}
      "#{SidekiqUniqueJobs::Config.unique_prefix}:#{Digest::MD5.hexdigest(Sidekiq.dump_json(md5_arguments))}"
    end
  end
end
