require 'bundler/gem_tasks'
require 'rubocop/rake_task'
require 'rspec/core/rake_task'

RSpec::Core::RakeTask.new(:spec)
RuboCop::RakeTask.new

task default: %i[spec rubocop]
