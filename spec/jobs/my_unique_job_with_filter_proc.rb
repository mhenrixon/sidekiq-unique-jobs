class MyUniqueJobWithFilterProc
  include Sidekiq::Worker
  sidekiq_options queue: :customqueue,
                  retry: true,
                  backtrace: true,
                  unique: :until_executed,
                  unique_args: (lambda do |args|
                    options = args.extract_options!
                    [args.first, options['type']]
                  end)

  def perform(*)
    # NO-OP
  end
end
