# frozen_string_literal: true

source "https://rubygems.org"
gemspec

LOCAL_GEMS = "Gemfile.local"

gem "appraisal"
gem "bundler"
gem "gem-release"
gem "github-markup"
gem "rack-test"
gem "rake"
gem "rspec"
gem "rspec-html-matchers"
gem "rspec-its"
gem "sinatra"
gem "timecop"
gem "yard"

platforms :mri do
  gem "rubocop-mhenrixon"
end

if respond_to?(:install_if)
  install_if -> { RUBY_PLATFORM.include?("darwin") } do
    gem "concurrent-ruby-ext"
    gem "fasterer"
    gem "fuubar"
    gem "github_changelog_generator"
    gem "hiredis"
    gem "pry"
    gem "redcarpet", "~> 3.4"
    gem "reek", ">= 5.3"
    gem "rspec-benchmark"
    gem "rspec-nc"
    gem "ruby-prof", ">= 0.17.0", require: false
    gem "simplecov-sublime", ">= 0.21.2", require: false
    gem "stackprof", ">= 0.2.9", require: false
    gem "test-prof"
  end
end

eval(File.read(LOCAL_GEMS)) if File.exist?(LOCAL_GEMS) # rubocop:disable Security/Eval
