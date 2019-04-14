# frozen_string_literal: true

source "https://rubygems.org"
gemspec

gem "appraisal", "~> 2.2.0"
gem "rspec-eventually", require: false
gem "rspec-its",        require: false
gem "rspec-retry",      require: false
gem "sidekiq", git: "https://github.com/mperham/sidekiq.git", branch: "6-0"

platforms :mri_25 do
  gem "benchmark-ips"
  gem "fasterer"
  gem "fuubar"
  gem "guard"
  gem "guard-reek"
  gem "guard-rspec"
  gem "guard-rubocop"
  gem "memory_profiler"
  gem "pry"
  gem "redcarpet", "~> 3.4"
  gem "reek", ">= 5.3"
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rspec"
  gem "simplecov-json"
  gem "travis"
end
