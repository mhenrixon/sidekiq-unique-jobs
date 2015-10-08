class UntilAndWhileExecuting
  include Sidekiq::Worker

  sidekiq_options queue: :working, unique: :until_and_while_executing

  def perform
  end
end
