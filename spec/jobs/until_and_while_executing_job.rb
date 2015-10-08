class UntilAndWhileExecuting
  include Sidekiq::Worker

  sidekiq_options queue: :working
  sidekiq_options unique: :until_and_while_executing

  def perform
  end
end
