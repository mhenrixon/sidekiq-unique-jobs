require 'sidekiq_unique_jobs/lib'

begin
  require 'mock_redis'
rescue LoadError
  raise 'To test using Sidekiq::Testing.inline!' \
        ' Please add `gem "mock_redis" to your gemfile.'
end

module SidekiqUniqueJobs
  def self.redis_mock
    @redis_mock ||= MockRedis.new
  end
end
