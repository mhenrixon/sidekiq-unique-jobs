require 'time'
require 'logger'
require 'fcntl'

module Sidekiq::Logging
  def self.with_context(msg)
    Thread.current[:sidekiq_context] = []
    Thread.current[:sidekiq_context] << msg
    yield
  ensure
    Thread.current[:sidekiq_context] = {}
  end

  def logger
    Sidekiq.logger
  end
end
