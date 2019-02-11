# frozen_string_literal: true

require "rspec/core/rake_task"
require "rubocop/rake_task"

Dir.glob("#{File.expand_path(__dir__)}/lib/tasks/**/*.rake").each { |f| import f }

RuboCop::RakeTask.new(:style)
RSpec::Core::RakeTask.new(:spec)

require "yard"
YARD::Rake::YardocTask.new do |t|
  t.files   = %w[lib/sidekiq_unique_jobs/**/*.rb"]
  t.options = %w[
    --no-private
    --markup=markdown
    --markup-provider=redcarpet
    --readme README.md
  ]
end

task default: [:style, :spec]

task :release do
  sh("./update_docs.sh")
  sh("gem release --tag --push")
  Rake::Task["changelog"].invoke
  sh("gem bump --file lib/sidekiq_unique_jobs/version.rb")
end
