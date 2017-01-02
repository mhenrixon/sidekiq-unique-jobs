class JustAWorker
  include Sidekiq::Worker

  sidekiq_options unique: :until_executed, queue: 'testqueue'

  def perform; end
end
