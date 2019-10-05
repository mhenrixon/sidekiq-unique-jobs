# frozen_string_literal: true

require "bundler/setup"

if RUBY_ENGINE == "ruby" && RUBY_VERSION >= "2.6" && RUBY_VERSION < "2.7"
  require "simplecov" unless %w[false 0].include?(ENV["COV"])

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

LOGLEVEL = ENV.fetch("LOGLEVEL") { "ERROR" }.upcase

SidekiqUniqueJobs.configure do |config|
  config.logger.level = Logger.const_get(LOGLEVEL)
  config.debug_lua    = %w[1 true].include?(ENV["DEBUG_LUA"])
  config.max_history  = 10
  config.lock_info    = true
end

require "sidekiq/redis_connection"

Dir[File.join(File.dirname(__FILE__), "support", "**", "*.rb")].each { |f| require f }
Dir[File.join(File.dirname(__FILE__), "..", "examples", "**", "*.rb")].each { |f| require f }

RSpec.configure do |config|
  config.define_derived_metadata do |meta|
    meta[:aggregate_failures] = true
  end
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end
  config.mock_with :rspec do |mocks|
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
