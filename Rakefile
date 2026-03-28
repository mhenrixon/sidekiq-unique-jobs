# frozen_string_literal: true

Dir.glob("#{File.expand_path(__dir__)}/lib/tasks/**/*.rake").each { |f| import f }

begin
  require "reek/rake/task"
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
rescue LoadError
  puts "Reek is currently unavailable"

  desc "Template Reek task"
  task :reek do
    puts "Should be running reek"
  end
end

def changed_files(pedantry)
  `git diff-tree --no-commit-id --name-only -r HEAD~#{pedantry} HEAD`
    .split("\n").select { |f| f.match(/(\.rb\z)|Rakefile/) && File.exist?(f) && !f.include?("db") }
end

begin
  require "rubocop/rake_task"
  RuboCop::RakeTask.new(:rubocop) do |task|
    # task.patterns = changed_files(5)
    task.options = %w[-DEP --format fuubar]
  end
rescue LoadError
  puts "Rubocop is currently unavailable"

  desc "Template Rubocop task"
  task :rubocop do
    puts "Should be running rubocop"
  end
end

desc "Runs style validations"
task style: [:reek, :rubocop]

begin
  require "rspec/core/rake_task"

  RSpec::Core::RakeTask.new(:rspec) do |t|
    t.rspec_opts = "--format Fuubar --format Nc"
  end
rescue LoadError
  puts "RSpec is currently not available"

  desc "Template RSpec task"
  task :rspec do
    puts "Should be running rspec"
  end
end

begin
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
rescue LoadError
  puts "Yard is currently unavailable"

  desc "Template Yard task"
  task :yard do
    puts "Should be running yard"
  end
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

desc "Build gem and verify contents"
task :build do
  sh("gem build sidekiq-unique-jobs.gemspec --strict")
  gem_file = Dir["sidekiq-unique-jobs-*.gem"].first
  sh("gem unpack #{gem_file} --target /tmp/gem-verify")
  puts "\n=== Gem contents ==="
  sh("find /tmp/gem-verify -type f | sort")
  sh("rm -rf /tmp/gem-verify #{gem_file}")
end

desc "Release a new version (rake release[1.2.3] or rake release[pre] to bump pre)"
task :release, [:version] do |_t, args|
  require "sidekiq_unique_jobs/version"

  new_version = args[:version]
  abort "Usage: rake release[X.Y.Z] or rake release[pre]" unless new_version

  current = SidekiqUniqueJobs::VERSION
  prerelease = new_version.match?(/alpha|beta|rc|pre/) || new_version == "pre"

  if new_version == "pre"
    new_version = current
    prerelease = true
  end

  tag = "v#{new_version}"

  puts "Current version: #{current}"
  puts "New version:     #{new_version}"
  puts "Tag:             #{tag}"
  puts "Pre-release:     #{prerelease}"
  puts ""

  # Update version file if needed
  version_file = "lib/sidekiq_unique_jobs/version.rb"
  if new_version != current
    content = File.read(version_file)
    content.sub!(/VERSION = ".*"/, "VERSION = \"#{new_version}\"")
    File.write(version_file, content)
    puts "Updated #{version_file}"
  end

  # Verify gem builds cleanly
  sh("gem build sidekiq-unique-jobs.gemspec --strict")
  sh("rm -f sidekiq-unique-jobs-*.gem")

  # Commit, push, and create release
  if new_version != current
    sh("git add #{version_file}")
    sh("git commit -m 'chore: bump version to #{new_version}'")
  end
  sh("git push origin main")

  pre_flag = prerelease ? "--prerelease" : ""
  sh("gh release create #{tag} --generate-notes --target main #{pre_flag}".strip)

  puts ""
  puts "Release #{tag} created! CI will handle the rest:"
  puts "  - Run tests"
  puts "  - Build + verify gem"
  puts "  - Sign with Sigstore"
  puts "  - Publish to RubyGems"
  puts "  - Upload assets to the release"
end
