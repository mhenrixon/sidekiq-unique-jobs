# frozen_string_literal: true

source "https://rubygems.org"
gemspec

LOCAL_GEMS = "Gemfile.local"

gem "appraisal",        ">= 2.2"
gem "rspec-eventually", require: false
gem "rspec-its",        require: false

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
  gem "simplecov-material"
  gem "simplecov-oj"
  gem "travis"
end

if respond_to?(:install_if)
  install_if -> { RUBY_PLATFORM =~ /darwin/ } do
    gem "fuubar"
    gem "pry"
    gem "rspec-nc"
  end
end

eval(File.read(LOCAL_GEMS)) if File.exist?(LOCAL_GEMS) # rubocop:disable Security/Eval
