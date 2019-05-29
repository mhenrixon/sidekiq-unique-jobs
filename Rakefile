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

RuboCop::RakeTask.new(:rubocop) do |t|
  # t.
end

task style: [:reek, :rubocop]

RSpec::Core::RakeTask.new(:rspec)

require "yard"
YARD::Rake::YardocTask.new do |t|
  t.files   = %w[lib/sidekiq_unique_jobs/**/*.rb]
  t.options = %w[
    --exclude lib/sidekiq_unique_jobs/testing.rb
    --exclude lib/sidekiq/logging.rb
    --exclude lib/sidekiq_unique_jobs/web/helpers.rb
    --exclude lib/redis.rb
    --no-private
    --markup=markdown
    --markup-provider=redcarpet
    --readme README.md
  ]
  t.stats_options = %w[
    --exclude lib/sidekiq/logging.rb
    --exclude lib/sidekiq_unique_jobs/testing.rb
    --exclude lib/sidekiq_unique_jobs/web/helpers.rb
    --exclude lib/sidekiq_unique_jobs/redis.rb
    --no-private
    --compact
    --list-undoc
  ]
end

task default: [:style, :rspec]

task :release do
  sh("./update_docs.sh")
  sh("gem release --tag --push")
  Rake::Task["changelog"].invoke
  sh("gem bump --file lib/sidekiq_unique_jobs/version.rb")
end
