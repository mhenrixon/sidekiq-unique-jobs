class UniqueWorker
  include Sidekiq::Worker
  sidekiq_options :queue => :working, :retry => 1, :backtrace => 10
  sidekiq_options :unique => true

  sidekiq_retries_exhausted do |msg|
    Sidekiq.logger.warn "Failed #{msg['class']} with #{msg['args']}: #{msg['error_message']}"
  end

  def self.params
    @params ||= []
  end

  def perform(param)
    UniqueWorker.params << param
  end
end

RSpec.configure do |config|
  config.before(:each) { UniqueWorker.params.clear }
end
