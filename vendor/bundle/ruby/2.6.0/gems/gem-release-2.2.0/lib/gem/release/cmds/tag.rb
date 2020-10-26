require 'gem/release/cmds/base'

module Gem
  module Release
    module Cmds
      class Tag < Base
        summary "Tags the HEAD commit with the gem's current version."

        description <<-str.split("\n").map(&:lstrip).join("\n")
          Creates an annotated tag for the current HEAD commit, using the gem's
          current version.

          Optionally pushes the tag to the origin repository.

          If one or many arguments are given then gemspecs with the same names
          will be searched, and the working directory changed to their respective
          directories. If `--recurse` is given then the directories all gem names from
          all gemspecs in this directory or any of its subdirectories will be used.
          This assumes that these directories are separate git repositories.

          The tag name will be `v[version]`.  For example, if the current version is
          `1.0.0`, then The tag is created using the command `git tag -am "tag v1.0.0"
          v1.0.0`.
        str

        DEFAULTS = {
          push:   false,
          remote: 'origin',
          sign:   false
        }.freeze

        DESCR = {
          push:   'Push tag to the remote git repository',
          remote: 'Git remote to push to',
          sign:   'GPG sign the tag',
        }.freeze

        opt '-p', '--[no-]push', descr(:push) do |value|
          opts[:push] = value
        end

        opt '--remote REMOTE', descr(:remote) do |value|
          opts[:remote] = value
        end

        opt '-s', '--sign', descr(:sign) do |value|
          opts[:sign] = value
        end

        MSGS = {
          tag:       'Tagging %s as version %s',
          exists:    'Skipping %s, tag already exists.',
          git_tag:   'Creating git tag %s',
          git_push:  'Pushing tags to the %s git repository',
          no_remote: 'Cannot push to missing git remote %s',
          git_dirty: 'Uncommitted changes found. Please commit or stash.',
        }.freeze

        CMDS = {
          git_tag:   'git tag -am "tag %s" %s %s',
          git_push:  'git push --tags %s'
        }.freeze

        def run
          in_gem_dirs do
            announce :tag, gem.name, target_version
            validate
            tag_and_push
          end
        end

        private

          def validate
            abort :git_dirty unless git.clean?
            abort :no_remote, remote if push? && !git.remotes.include?(remote)
          end

          def tag_and_push
            return info :exists, tag_name if exists?
            tag
            push if opts[:push]
          end

          def exists?
            git.tags.include?(tag_name)
          end

          def tag
            cmd :git_tag, tag_name, tag_name, opts[:sign] ? '--sign' : ''
          end

          def push
            cmd :git_push, remote
          end

          def tag_name
            "v#{target_version}"
          end

          def push?
            opts[:push] || opts[:push_commit]
          end

          def remote
            opts[:remote]
          end

          def target_version
            opts[:version] || gem.version
          end
      end
    end
  end
end
