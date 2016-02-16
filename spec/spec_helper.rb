if RUBY_ENGINE == 'ruby' && RUBY_VERSION >= '2.2.3'
  if ENV['CI']
    require 'codeclimate-test-reporter'
    CodeClimate::TestReporter.start
  else
    require 'simplecov'
  end

  begin
    require 'pry-byebug'
  rescue LoadError
    puts 'Pry unavailable'
  end
end

require 'rspec'
require 'rspec/its'

require 'celluloid_with_fallback'
require 'sidekiq'
require 'sidekiq/util'
require 'sidekiq-unique-jobs'
require 'sidekiq_unique_jobs/testing'
require 'timecop'

require 'sidekiq/simulator'

Sidekiq::Testing.disable!
Sidekiq.logger.level = "Logger::#{ENV.fetch('LOGLEVEL') { 'error' }.upcase}".constantize

require 'sidekiq/redis_connection'

begin
  require 'redis-namespace'
rescue LoadError
  puts 'Redis Namespace unavailable'
end

REDIS_URL ||= ENV['REDIS_URL'] || 'redis://localhost/15'.freeze
REDIS_NAMESPACE ||= 'unique-test'.freeze
REDIS_OPTIONS ||= { url: REDIS_URL } # rubocop:disable MutableConstant
REDIS_OPTIONS[:namespace] = REDIS_NAMESPACE if defined?(Redis::Namespace)
REDIS ||= Sidekiq::RedisConnection.create(REDIS_OPTIONS)

Sidekiq.configure_client do |config|
  config.redis = REDIS_OPTIONS
end

Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |f| require f }
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.filter_run :focus unless ENV['CI']
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.warnings = false
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed
end

Dir[File.join(File.dirname(__FILE__), 'jobs', '**', '*.rb')].each { |f| require f }
