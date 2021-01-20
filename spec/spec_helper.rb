# frozen_string_literal: true

require "bundler/setup"

if RUBY_ENGINE == "ruby" && RUBY_VERSION >= "2.6"
  require "simplecov" if ENV["COV"]

  begin
    require "pry"
  rescue LoadError
    puts "Pry unavailable"
  end
end

require "rspec"
require "rspec/its"

require "sidekiq"
require "sidekiq/api"
require "sidekiq/util"
require "sidekiq-unique-jobs"
require "timecop"
require "sidekiq_unique_jobs/testing"

Sidekiq.log_format = :json if Sidekiq.respond_to?(:log_format)
Redis.exists_returns_integer = true if Redis.respond_to?(:exists_returns_integer=)
LOGLEVEL = ENV.fetch("LOGLEVEL", "ERROR").upcase
ORIGINAL_SIDEKIQ_OPTIONS = Sidekiq.default_worker_options

Sidekiq.default_worker_options = {
  backtrace: true,
  retry: true,
}

Sidekiq.configure_server do |config|
  config.redis = { url: ENV["REDIS_URL"], driver: :hiredis }

  config.server_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Server
  end

  config.error_handlers << ->(ex, ctx_hash) { p ex, ctx_hash }
  config.death_handlers << lambda do |job, _ex|
    digest = job["lock_digest"]
    SidekiqUniqueJobs::Digests.delete_by_digest(digest) if digest
  end
end

Sidekiq.configure_client do |config|
  config.redis = { url: ENV["REDIS_URL"], driver: :hiredis }

  config.client_middleware do |chain|
    chain.add SidekiqUniqueJobs::Middleware::Client
  end
end

SidekiqUniqueJobs.configure do |config|
  config.logger.level = Logger.const_get(LOGLEVEL)
  config.debug_lua    = %w[1 true].include?(ENV["DEBUG_LUA"])
  config.max_history  = 10
  config.lock_info    = true
end

require "sidekiq/redis_connection"

Dir[File.join(File.dirname(__FILE__), "support", "**", "*.rb")].sort.each { |f| require f }
Dir[File.join(File.dirname(__FILE__), "..", "examples", "**", "*.rb")].sort.each { |f| require f }

RSpec.configure do |config|
  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end

  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
    mocks.allow_message_expectations_on_nil = true
    mocks.verify_partial_doubles = true
  end
  config.example_status_persistence_file_path = ".rspec_status"
  config.filter_run :focus unless ENV["CI"]
  config.run_all_when_everything_filtered = true
  config.disable_monkey_patching!
  config.warnings = false
  config.default_formatter = "doc" if config.files_to_run.one?
  config.order = :random

  config.include SidekiqUniqueJobs::Testing

  Kernel.srand config.seed
end

RSpec::Support::ObjectFormatter.default_instance.max_formatted_output_length = 10_000

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
