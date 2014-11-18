begin
  require 'mock_redis'
rescue
  raise 'To test using Sidekiq::Testing.inline!' \
        ' Please add `gem "mock_redis" to your gemfile.'
end

module SidekiqUniqueJobs
  def self.redis_mock
    @redis_mock ||= MockRedis.new
  end
end
