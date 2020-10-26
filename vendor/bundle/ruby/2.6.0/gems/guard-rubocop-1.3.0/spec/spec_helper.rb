RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end

  config.filter_run_when_matching :focus

  config.example_status_persistence_file_path = 'spec/examples.txt'

  config.disable_monkey_patching!

  config.default_formatter = 'doc' if config.files_to_run.one?

  config.order = :random

  Kernel.srand config.seed
end

Dir[File.join(File.dirname(__FILE__), 'support', '*')].each do |path|
  require path
end

# Initialize Guard for running tests.
require 'guard'
Guard.setup(notify: false)

require 'guard/rubocop'
