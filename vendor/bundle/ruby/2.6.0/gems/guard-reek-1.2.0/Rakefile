require "bundler/gem_tasks"
require 'rspec/core/rake_task'

task default: :ci

task :ci do
  Rake::Task["spec"].invoke
end

RSpec::Core::RakeTask.new
