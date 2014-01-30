module SidekiqUniqueJobs
  def self.redis_mock
     @redis_mock ||= begin
       require 'mock_redis'
       MockRedis.new
     end
  end

  def self.testing_enabled?
    defined?(Sidekiq::Testing) && Sidekiq::Testing.enabled?
  end

  def self.use_redis_mock?
    return(!!@use_redis_mock) unless nil == @use_redis_mock
    @use_redis_mock = true
  end

  class << self
    attr_accessor :use_redis_mock
  end

  def self.enable_redis_mock!
    self.use_redis_mock = true
  end

  def self.disable_redis_mock!
    self.use_redis_mock = false
  end
end
