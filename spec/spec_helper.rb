# frozen_string_literal: true

VERSION_REGEX = /(?<operator>[<>=]+)?\s?(?<version>(\d+.?)+)/m
if RUBY_ENGINE == 'ruby' && RUBY_VERSION >= '2.5.1'
  require 'simplecov'

  begin
    require 'pry-byebug'
  rescue LoadError
    puts 'Pry unavailable'
  end
end

require 'rspec'
require 'rspec/its'

require 'sidekiq'
require 'sidekiq/util'
require 'sidekiq-unique-jobs'
require 'timecop'
require 'sidekiq_unique_jobs/testing'
require 'sidekiq/simulator'

Sidekiq::Testing.disable!
Sidekiq.logger = Logger.new('/dev/null')
SidekiqUniqueJobs.logger.level = Object.const_get("Logger::#{ENV.fetch('LOGLEVEL') { 'error' }.upcase}")

require 'sidekiq/redis_connection'

REDIS_URL ||= ENV['REDIS_URL'] || 'redis://localhost/15'
REDIS_NAMESPACE ||= 'unique-test'
REDIS_OPTIONS ||= { url: REDIS_URL } # rubocop:disable MutableConstant
REDIS_OPTIONS[:namespace] = REDIS_NAMESPACE if defined?(Redis::Namespace)
REDIS ||= Sidekiq::RedisConnection.create(REDIS_OPTIONS)

Sidekiq.configure_client do |config|
  config.redis = REDIS_OPTIONS
end

Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |f| require f }

RSpec.configure do |config| # rubocop:disable BlockLength
  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.example_status_persistence_file_path = 'spec/examples.txt'
  config.filter_run :focus unless ENV['CI']
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.warnings = false
  config.default_formatter = 'doc' if config.files_to_run.one?
  config.order = :random
  Kernel.srand config.seed

  config.before(:each) do
    SidekiqUniqueJobs.configure do |unique_config|
      unique_config.redis_test_mode = :redis
    end
    Sidekiq.redis = REDIS
    Sidekiq.redis(&:flushdb)
    Sidekiq::Worker.clear_all
    Sidekiq::Queues.clear_all

    if Sidekiq::Testing.respond_to?(:server_middleware)
      Sidekiq::Testing.server_middleware do |chain|
        chain.add SidekiqUniqueJobs::Server::Middleware
      end
    end
    enable_delay = defined?(Sidekiq::Extensions) && Sidekiq::Extensions.respond_to?(:enable_delay!)
    Sidekiq::Extensions.enable_delay! if enable_delay
  end

  config.after(:each) do
    Sidekiq.redis(&:flushdb)
    respond_to_middleware = defined?(Sidekiq::Testing) && Sidekiq::Testing.respond_to?(:server_middleware)
    Sidekiq::Testing.server_middleware(&:clear) if respond_to_middleware
  end
end

Dir[File.join(File.dirname(__FILE__), 'jobs', '**', '*.rb')].each { |f| require f }

def capture(stream)
  begin
    stream = stream.to_s
    eval("$#{stream} = StringIO.new") # rubocop:disable Security/Eval, Style/EvalWithLocation
    yield
    result = eval("$#{stream}").string # rubocop:disable Security/Eval, Style/EvalWithLocation
  ensure
    eval("$#{stream} = #{stream.upcase}") # rubocop:disable Security/Eval, Style/EvalWithLocation
  end

  result
end
