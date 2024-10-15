# frozen_string_literal: true

source "https://rubygems.org"
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

gemspec

LOCAL_GEMS = "Gemfile.local"

gem "appraisal", github: "thoughtbot/appraisal"
gem "faraday-retry"
gem "gem-release"
gem "github-markup"
gem "rack-test"
gem "rake"
gem "rspec"
gem "rspec-benchmark"
gem "rspec-html-matchers"
gem "rspec-its"
gem "rubocop-mhenrixon"
gem "simplecov-sublime", ">= 0.21.2", require: false
gem "sinatra"
gem "timecop"
gem "toxiproxy"
gem "yard"

platforms :mri do
  gem "concurrent-ruby-ext"
end

if respond_to?(:install_if)
  install_if -> { RUBY_PLATFORM.include?("darwin") } do
    gem "fuubar"
    gem "github_changelog_generator"
    gem "pry"
    gem "redcarpet", "~> 3.4"
    gem "ruby-prof", ">= 0.17.0", require: false
    gem "stackprof", ">= 0.2.9", require: false
    gem "test-prof"
  end
end

eval(File.read(LOCAL_GEMS)) if File.exist?(LOCAL_GEMS) # rubocop:disable Security/Eval
