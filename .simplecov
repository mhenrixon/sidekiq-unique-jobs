require 'simplecov-json'

SimpleCov.command_name 'RSpec'
# SimpleCov.refuse_coverage_drop
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter,
]

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/bin/'
  add_filter '/gemfiles/'
  add_filter '/examples/'

  add_group 'Client', 'lib/sidekiq_unique_jobs/client'
  add_group 'Locks', 'lib/sidekiq_unique_jobs/lock'
  add_group 'Server', 'lib/sidekiq_unique_jobs/server'
  add_group 'Timeout', 'lib/sidekiq_unique_jobs/timeout'
end
