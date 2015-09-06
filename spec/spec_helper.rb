if RUBY_ENGINE == 'ruby'
  if ENV['CI']
    require 'codeclimate-test-reporter'
    CodeClimate::TestReporter.start
  else
    require 'simplecov'
    require 'simplecov-json'
    SimpleCov.refuse_coverage_drop
    SimpleCov.formatters = [
      SimpleCov::Formatter::HTMLFormatter,
      SimpleCov::Formatter::JSONFormatter
    ]
    SimpleCov.start do
      add_filter '/spec/'
      add_filter '/bin/'
      add_filter '/gemfiles/'
    end
  end
end

begin
  require 'pry-suite'
rescue LoadError
  puts 'Pry unavailable'
end

require 'rspec'

require 'celluloid/test'
require 'sidekiq'
require 'sidekiq/util'
require 'sidekiq-unique-jobs'
Sidekiq.logger.level = Logger::ERROR
require 'sidekiq_unique_jobs/testing'

require 'rspec-sidekiq'

Sidekiq::Testing.disable!

require 'sidekiq/redis_connection'
redis_url = ENV['REDIS_URL'] || 'redis://localhost/15'
REDIS = Sidekiq::RedisConnection.create(url: redis_url, namespace: 'sidekiq-unique-jobs-testing')

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
  config.warnings = true
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed
end

RSpec::Sidekiq.configure do |config|
  # Clears all job queues before each example
  config.clear_all_enqueued_jobs = true

  # Whether to use terminal colours when outputting messages
  config.enable_terminal_colours = true

  # Warn when jobs are not enqueued to Redis but to a job array
  config.warn_when_jobs_not_processed_by_sidekiq = false
end
