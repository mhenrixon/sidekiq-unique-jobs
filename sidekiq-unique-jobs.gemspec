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

  spec.post_install_message = <<~POST_INSTALL
    IMPORTANT!

    Automatic configuration of the sidekiq middleware is no longer done.
    Please see: https://github.com/mhenrixon/sidekiq-unique-jobs/blob/master/README.md#add-the-middleware

    This version deprecated the following sidekiq_options

      - sidekiq_options lock_args: :method_name

    It is now configured with:

      - sidekiq_options lock_args_method: :method_name

    This is also true for `Sidekiq.default_worker_options`

    We also deprecated the global configuration options:
      - default_lock_ttl
      - default_lock_ttl=
      - default_lock_timeout
      - default_lock_timeout=

    The new methods to use are:
      - lock_ttl
      - lock_ttl=
      - lock_timeout
      - lock_timeout=
  POST_INSTALL

  spec.bindir        = "bin"
  spec.executables   = %w[uniquejobs]

  spec.files         = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").select do |file|
      file.match(%r{^(lib/*|bin/uniquejobs|README|LICENSE|CHANGELOG)})
    end
  end

  spec.require_paths = ["lib"]

  spec.required_ruby_version = ">= 2.5"

  spec.add_dependency "brpoplpush-redis_script", "> 0.1.1", "<= 2.0.0"
  spec.add_dependency "concurrent-ruby", "~> 1.0", ">= 1.0.5"
  spec.add_dependency "sidekiq", ">= 5.0", "< 8.0"
  spec.add_dependency "thor", ">= 0.20", "< 3.0"
  spec.metadata = {
    "rubygems_mfa_required" => "true",
  }
end
