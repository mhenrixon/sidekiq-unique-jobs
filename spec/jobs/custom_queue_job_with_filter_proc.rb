class CustomQueueJobWithFilterProc < CustomQueueJob
  # slightly contrived example of munging args to the
  # worker and removing a random bit.
  sidekiq_options unique: :until_timeout,
                  unique_args: (lambda do |*args|
                    options = args.extract_options!
                    options.delete(:random)
                    [args, options]
                  end)
end
