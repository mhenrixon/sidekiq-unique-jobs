require 'mock_redis'
module SidekiqUniqueJobs
  def self.redis_mock
    @redis_mock ||= MockRedis.new
  end
end
