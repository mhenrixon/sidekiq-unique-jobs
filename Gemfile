# frozen_string_literal: true

source "https://rubygems.org"
gemspec

gem "appraisal", "~> 2.2.0"
gem "rspec-eventually", require: false
gem "rspec-its",        require: false
gem "sidekiq", git: "https://github.com/mperham/sidekiq.git", branch: "6-0"

platforms :mri do
  gem "benchmark-ips"
  gem "fasterer"
  gem "fuubar"
  gem "guard"
  gem "guard-reek"
  gem "guard-rspec"
  gem "guard-rubocop"
  gem "hiredis"
  gem "memory_profiler"
  gem "pry"
  gem "redcarpet", "~> 3.4"
  gem "reek", ">= 5.3"
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rspec"
  gem "ruby-prof"
  gem "simplecov-json"
  gem "stackprof"
  gem "test-prof"
  gem "travis"
end
