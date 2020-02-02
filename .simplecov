require 'simplecov-material'
require 'simplecov-oj'

SimpleCov.command_name 'RSpec'
# SimpleCov.refuse_coverage_drop
SimpleCov.formatters = [
  SimpleCov::Formatter::MaterialFormatter,
  SimpleCov::Formatter::OjFormatter,
]

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/bin/'
  add_filter '/gemfiles/'
  add_filter '/lib/sidekiq/'
  add_filter '/lib/sidekiq_unique_jobs/testing.rb'
  add_filter '/lib/sidekiq_unique_jobs/core_ext.rb'

  add_group 'Locks',      'lib/sidekiq_unique_jobs/lock'
  add_group 'Middelware', 'lib/sidekiq_unique_jobs/middleware'
  add_group 'Redis',      'lib/sidekiq_unique_jobs/redis'
  add_group 'Timeout',    'lib/sidekiq_unique_jobs/timeout'
end
