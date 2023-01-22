# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require "sidekiq_unique_jobs/version"

Gem::Specification.new do |spec|
  spec.name        = "sidekiq-unique-jobs"
  spec.version     = SidekiqUniqueJobs::VERSION
  spec.authors     = ["Mikael Henriksson"]
  spec.email       = ["mikael@mhenrixon.com"]
  spec.homepage    = "https://github.com/mhenrixon/sidekiq-unique-jobs"
  spec.license     = "MIT"
  spec.summary     = <<~SUMMARY
    Sidekiq middleware that prevents duplicates jobs
  SUMMARY
  spec.description = <<~DESCRIPTION
    Prevents simultaneous Sidekiq jobs with the same unique arguments to run.
    Highly configurable to suite your specific needs.
  DESCRIPTION

  raise "RubyGems 2.0 or newer is required to protect against public gem pushes." unless spec.respond_to?(:metadata)

  spec.metadata["homepage_uri"]      = spec.homepage
  spec.metadata["bug_tracker_uri"]   = "https://github.com/mhenrixon/sidekiq-unique-jobs/issues"
  spec.metadata["documentation_uri"] = "https://github.com/mhenrixon/sidekiq-unique-jobs"
  spec.metadata["source_code_uri"]   = "https://github.com/mhenrixon/sidekiq-unique-jobs"
  spec.metadata["changelog_uri"]     = "https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/CHANGELOG.md"
  spec.metadata["funding_uri"]       = "https://github.com/mhenrixon/sidekiq-unique-jobs"

  spec.bindir        = "bin"
  spec.executables   = %w[uniquejobs]

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").select do |file|
      file.match(%r{^(lib/*|bin/uniquejobs|README|LICENSE|CHANGELOG)})
    end
  end

  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.7"

  spec.add_dependency "brpoplpush-redis_script", "> 0.1.1", "<= 2.0.0"
  spec.add_dependency "concurrent-ruby", "~> 1.0", ">= 1.0.5"
  spec.add_dependency "sidekiq", ">= 7.0.0", "< 8.0.0"
  spec.add_dependency "thor", ">= 1.0", "< 3.0"
  spec.metadata = {
    "rubygems_mfa_required" => "true",
  }
end
