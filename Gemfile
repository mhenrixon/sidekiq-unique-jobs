# frozen_string_literal: true

source 'https://rubygems.org'
gemspec

gem 'appraisal',        '~> 2.2.0'
gem 'rspec-its',        require: false
gem 'rspec-retry',      require: false
gem 'rspec-eventually', require: false

platforms :mri_25 do
  gem 'benchmark-ips'
  gem 'fasterer'
  gem 'guard'
  gem 'guard-reek'
  gem 'guard-rspec'
  gem 'guard-rubocop'
  gem 'memory_profiler'
  gem 'reek', '>= 5.3',
  gem 'pry'
  gem 'rubocop'
  gem 'rubocop-rspec'
  gem 'simplecov-json'
  gem 'rb-readline'
end
