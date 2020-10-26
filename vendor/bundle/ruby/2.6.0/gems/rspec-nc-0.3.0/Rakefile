#!/usr/bin/env rake

require 'bundler/gem_tasks'
require 'rspec/core/rake_task'
require 'wwtd/tasks'

RSpec::Core::RakeTask.new(:spec) do |t|
  t.rspec_opts = "--format=#{ENV['FORMATTER']}" if ENV['FORMATTER']
end

task :default => :wwtd
