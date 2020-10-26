require 'gem/release/cmds/base'
require 'gem/release/context/github'

module Gem
  module Release
    module Cmds
      class Github < Base
        summary "Creates a GitHub release for the current version."

        description <<-str.split("\n").map(&:lstrip).join("\n")
          Creates a GitHub release for the current version.

          Requires a tag `v[version]` to be present or --tag to be given.
        str

        MSGS = {
          release:  'Creating GitHub release for %s version %s.',
          no_tag:   'Tag %s does not exist. Run `gem tag` or pass `--tag`.',
          no_repo:  'Could not determine the repository name. Please pass `--repo REPO`, or set homepage or metadata[:github_url] to the GitHub repository URL in the gemspec.',
          no_token: 'Could not determine the GitHub OAuth token. Please pass `--token TOKEN`. See https://developer.github.com/v3/#oauth2-token-sent-in-a-header for more details.',
        }.freeze

        def run
          in_gem_dirs do
            announce :release, gem.name, tag_name
            validate
            release
          end
        end

        private

          def validate
            abort :no_tag, tag_name unless tagged?
            abort :no_token unless token
          end

          def tagged?
            git.tags.include?(tag_name)
          end

          def release
            return if pretend?
            Context::Github.new(repo, data).release
          end

          def data
            {
              version:  gem.version,
              tag_name: tag_name,
              name:     "#{gem.name} #{tag_name}",
              descr:    descr,
              token:    token
            }
          end

          def tag_name
            "v#{gem.version}"
          end

          def repo
            opts[:repo] || repo_from(gem.spec.homepage) || repo_from(gem.spec.metadata[:github_url]) || abort(:no_repo)
          end

          def repo_from(url)
            url && url =~ %r(https://github\.com/(.*/.*)) && $1
          end

          def token
            opts[:token]
          end

          def descr
            opts[:descr]
          end
      end
    end
  end
end
