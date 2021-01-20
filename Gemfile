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
gem "rspec-its"
gem "sinatra"
gem "timecop"
gem "yard"

platforms :mri do
  gem "fasterer"
  gem "github_changelog_generator"
  gem "guard"
  gem "guard-bundler"
  gem "guard-reek"
  gem "guard-rspec"
  gem "guard-rubocop"
  gem "hiredis"
  gem "redcarpet", "~> 3.4"
  gem "reek", ">= 5.3"
  gem "rspec-benchmark"
  gem "rubocop-mhenrixon"
  gem "simplecov-sublime", "0.21.0", require: false
  gem "travis"
end

if respond_to?(:install_if)
  install_if -> { RUBY_PLATFORM.include?("darwin") } do
    gem "fuubar"
    gem "pry"
    gem "rspec-nc"
  end
end

eval(File.read(LOCAL_GEMS)) if File.exist?(LOCAL_GEMS) # rubocop:disable Security/Eval
