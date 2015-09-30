class QueueWorkerWithFilterMethod < QueueWorker
  sidekiq_options unique: true, unique_args: :args_filter

  def self.args_filter(*args)
    args.first
  end
end
