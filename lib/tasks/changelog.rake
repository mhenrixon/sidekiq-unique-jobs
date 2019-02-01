# frozen_string_literal: true

desc "Generate a Changelog"
task :changelog do
  # rubocop:disable Style/MutableConstant
  CHANGELOG_COMMAND ||= %w[
    github_changelog_generator
    -u
    mhenrixon
    -p
    stub_requests
    --no-verbose
    --token
  ]
  # rubocop:enable Style/MutableConstant

  sh(*CHANGELOG_COMMAND.push(ENV["CHANGELOG_GITHUB_TOKEN"]))
end
