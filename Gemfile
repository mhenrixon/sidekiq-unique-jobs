# frozen_string_literal: true

source "https://rubygems.org"
gemspec

LOCAL_GEMS = "Gemfile.local"

gem "appraisal",        ">= 2.2"
gem "rspec-eventually", require: false
gem "rspec-its",        require: false

platforms :jruby do
  gem 'pry-debugger-jruby'
end

platforms :mri do
  gem "benchmark-ips"
  gem "fasterer"
  gem "fuubar"
  gem "guard"
  gem "guard-bundler"
  gem "guard-reek"
  gem "guard-rspec"
  gem "guard-rubocop"
  gem "hiredis"
  gem "memory_profiler"
  gem "pry"
  gem "redcarpet", "~> 3.4"
  gem "reek", ">= 5.3"
  gem "rspec-benchmark"
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rspec"
  gem "ruby-prof"
  gem "simplecov-json"
  gem "stackprof"
  gem "terminal-notifier-guard"
  gem "test-prof"
  gem "toxiproxy"
  gem "travis"
end

eval(File.read(LOCAL_GEMS)) if File.exist?(LOCAL_GEMS) # rubocop:disable Security/Eval
