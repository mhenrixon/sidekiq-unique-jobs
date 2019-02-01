# frozen_string_literal: true

require "bundler/gem_tasks"
require "rspec/core/rake_task"
require "rubocop/rake_task"

Dir.glob("#{File.expand_path(__dir__)}/lib/tasks/**/*.rake").each { |f| import f }

RuboCop::RakeTask.new(:style)
RSpec::Core::RakeTask.new(:spec)

require "yard"
YARD::Rake::YardocTask.new do |t|
  t.files   = %w[lib/**/*.rb"]
  t.options = %w[
    --no-private
    --output-dir docs
    --readme README.md
    --output-dir docs
    --markup=markdown
    --markup-provider=redcarpet
  ]
end

task default: [:style, :spec]
