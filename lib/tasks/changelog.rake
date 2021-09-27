# frozen_string_literal: true

# rubocop:disable Style/MutableConstant
CHANGELOG_CMD = %w[
  github_changelog_generator
  --no-verbose
  --user
  mhenrixon
  --project
  sidekiq-unique-jobs
  --token
]
ADD_CHANGELOG_CMD = "git add --all"
COMMIT_CHANGELOG_CMD = "git commit -a -m 'Update changelog'"
# rubocop:enable Style/MutableConstant

desc "Generate a Changelog"
task :changelog do
  sh("git checkout master")
  sh(*CHANGELOG_CMD.push(ENV["CHANGELOG_GITHUB_TOKEN"]))
  sh(ADD_CHANGELOG_CMD)
  sh(COMMIT_CHANGELOG_CMD)
end
