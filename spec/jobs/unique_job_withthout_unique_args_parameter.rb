class UniqueJobWithoutUniqueArgsParameter
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue,
                  retry: true,
                  backtrace: true,
                  unique: :until_executed,
                  unique_args: :unique_args

  def perform(optional = true)
    # NO-OP
  end

  def self.unique_args; end
end
