class UniqueJobWithNoUniqueArgsMethod
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue,
                  retry: true,
                  backtrace: true,
                  unique: :until_executed,
                  unique_args: :filtered_args

  def perform(*)
    # NO-OP
  end
end
