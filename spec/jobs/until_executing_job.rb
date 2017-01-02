class UntilExecutingJob
  include Sidekiq::Worker

  sidekiq_options queue: :working, unique: :until_executing

  def perform; end
end
