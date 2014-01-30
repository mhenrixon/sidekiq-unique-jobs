module SidekiqUniqueJobs
  def self.redis_mock
     @redis_mock ||= begin
       require 'mock_redis'
       MockRedis.new
     end
  end
end
