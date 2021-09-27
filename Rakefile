# frozen_string_literal: true

require "reek/rake/task"
require "rspec/core/rake_task"
require "rubocop/rake_task"

Dir.glob("#{File.expand_path(__dir__)}/lib/tasks/**/*.rake").each { |f| import f }

Reek::Rake::Task.new(:reek) do |t|
  t.name          = "reek"
  t.config_file   = ".reek.yml"
  t.source_files  = "."
  t.reek_opts     = %w[
    --line-numbers
    --color
    --documentation
    --progress
    --single-line
    --sort-by smelliness
  ].join(" ")
  t.fail_on_error = true
  t.verbose       = true
end

def changed_files(pedantry)
  `git diff-tree --no-commit-id --name-only -r HEAD~#{pedantry} HEAD`
    .split("\n").select { |f| f.match(/(\.rb\z)|Rakefile/) && File.exist?(f) && !f.include?("db") }
end

RuboCop::RakeTask.new(:rubocop) do |task|
  # task.patterns = changed_files(5)
  task.options = %w[-DEP --format fuubar]
end

desc "Runs style validations"
task style: [:reek, :rubocop]

RSpec::Core::RakeTask.new(:rspec) do |t|
  t.rspec_opts = "--format Fuubar --format Nc"
end

require "yard"
YARD::Rake::YardocTask.new(:yard) do |t|
  t.files   = %w[lib/sidekiq_unique_jobs/**/*.rb]
  t.options = %w[
    --exclude lib/sidekiq_unique_jobs/testing.rb
    --exclude lib/sidekiq_unique_jobs/web/helpers.rb
    --exclude lib/redis.rb
    --no-private
    --embed-mixins
    --markup=markdown
    --markup-provider=redcarpet
    --readme README.md
    --files CHANGELOG.md,LICENSE.txt
  ]
  t.stats_options = %w[
    --exclude lib/sidekiq_unique_jobs/testing.rb
    --exclude lib/sidekiq_unique_jobs/web/helpers.rb
    --no-private
    --compact
    --list-undoc
  ]
end

task default: [:style, :rspec, :yard]

namespace :appraisal do
  namespace :rspec do
    desc "Runs rspec for all appraisals"
    task :all do
      sh("bundle exec appraisal rspec")
    end

    desc "Runs rspec for older appraisals than sidekiq 6"
    task :pre_sidekiq6 do
      sh("bundle exec appraisal sidekiq-4.0 rspec")
      sh("bundle exec appraisal sidekiq-4.1 rspec")
      sh("bundle exec appraisal sidekiq-4.2 rspec")
      sh("bundle exec appraisal sidekiq-5.0 rspec")
      sh("bundle exec appraisal sidekiq-5.1 rspec")
      sh("bundle exec appraisal sidekiq-5.2 rspec")
    end

    desc "Runs rspec for appraisals containing sidekiq 6 or greater"
    task :post_sidekiq6 do
      sh("bundle exec appraisal sidekiq-6.0 rspec")
      sh("bundle exec appraisal sidekiq-develop rspec")
    end

    task default: [:all]
  end
end

desc "Release a new gem version"
task :release do
  sh("bundle install")
  sh("bundle exec gem release --tag --push")
  sh("gem bump --file lib/sidekiq_unique_jobs/version.rb")
end
