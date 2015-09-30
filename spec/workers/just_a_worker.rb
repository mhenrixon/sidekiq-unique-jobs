class JustAWorker
  include Sidekiq::Worker

  sidekiq_options unique: true, queue: 'testqueue'

  def perform
  end
end
