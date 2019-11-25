# frozen_string_literal: true

source "https://rubygems.org"
gemspec

LOCAL_GEMS = "Gemfile.local"

gem "appraisal",        ">= 2.2"
gem "rspec-eventually", require: false
gem "rspec-its",        require: false

platforms :mri do
  gem "fasterer"
  gem "fuubar"
  gem "github_changelog_generator"
  gem "guard"
  gem "guard-bundler"
  gem "guard-reek"
  gem "guard-rspec"
  gem "guard-rubocop"
  gem "hiredis"
  gem "pry"
  gem "redcarpet", "~> 3.4"
  gem "reek", ">= 5.3"
  gem "rspec-benchmark"
  gem "rubocop"
  gem "rubocop-performance"
  gem "rubocop-rspec"
  gem "simplecov-json"
  gem "travis"
end

eval(File.read(LOCAL_GEMS)) if File.exist?(LOCAL_GEMS) # rubocop:disable Security/Eval
