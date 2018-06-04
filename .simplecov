require 'simplecov-json'

SimpleCov.command_name 'RSpec'
SimpleCov.refuse_coverage_drop
SimpleCov.formatters = [
  SimpleCov::Formatter::HTMLFormatter,
  SimpleCov::Formatter::JSONFormatter,
]

SimpleCov.start do
  add_filter '/spec/'
  add_filter '/bin/'
  add_filter '/gemfiles/'
end
