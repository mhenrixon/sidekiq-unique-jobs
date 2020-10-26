require 'gem/release/cmds/base'
require 'rubygems/commands/build_command'
require 'rubygems/commands/push_command'

module Gem
  module Release
    module Cmds
      class Release < Base
        summary 'Releases one or all gems in this directory.'

        description <<-str.split("\n").map(&:lstrip).join("\n")
          Builds one or many gems from the given gemspec(s), pushes them to rubygems.org
          (or another, compatible host), and removes the left over gem file.

          Optionally invoke `gem tag`.

          If no argument is given the first gemspec's name is assumed as the gem name.
          If one or many arguments are given then these will be used. If `--recurse` is
          given then all gem names from all gemspecs in this directory or any of its
          subdirectories will be used.
        str

        arg :gem_name, 'name of the gem (optional, will use the first gemspec, or all gemspecs if --recurse is given)'

        DEFAULTS = {
          tag:     false,
          push:    false,
          recurse: false
        }.freeze

        DESCR = {
          host:    'Push to a compatible host other than rubygems.org',
          key:     'Use the API key from ~/.gem/credentials',
          tag:     'Shortcut for running the `gem tag` command',
          push:    'Push tag to the remote git repository',
          github:  'Create a GitHub release',
          recurse: 'Recurse into directories that contain gemspec files',

          # region github

          descr: 'Description of the release',
          repo:  "Full name of the repository on GitHub, e.g. svenfuchs/gem-release (defaults to the repo name from the gemspec's homepage if this is a GitHub URL)",
          token: 'GitHub OAuth token'

          # endregion github
        }.freeze

        opt '-h', '--host HOST', descr(:host) do |value|
          opts[:host] = value
        end

        opt '-k', '--key KEY', descr(:key) do |value|
          opts[:key] = value
        end

        opt '-t', '--tag', descr(:tag) do |value|
          opts[:tag] = value
        end

        opt '-p', '--push', descr(:push) do |value|
          opts[:push] = value
        end

        opt '--recurse', descr(:recurse) do |value|
          opts[:recurse] = value
        end

        # region github

        opt '-g', '--github', descr(:github) do |value|
          opts[:github] = value
        end

        opt '-d', '--description DESCRIPTION', descr(:descr) do |value|
          opts[:descr] = value
        end

        opt '--repo REPO', descr(:repo) do |value|
          opts[:repo] = value
        end

        opt '--token TOKEN', descr(:token) do |value|
          opts[:token] = value
        end

        # endregion github

        MSGS = {
          release:   'Releasing %s with version %s',
          build:     'Building %s',
          push:      'Pushing %s',
          cleanup:   'Deleting left over gem file %s',
          git_dirty: 'Uncommitted changes found. Please commit or stash.',
        }.freeze

        CMDS = {
          cleanup: 'rm -f %s'
        }.freeze

        def run
          in_gem_dirs do
            validate
            release
          end
          tag    if opts[:tag]
          github if opts[:github]
        end

        private

          def validate
            abort :git_dirty unless git.clean?
          end

          def release
            announce :release, gem.name, target_version
            return if pretend?
            build
            push
          ensure
            cleanup
          end

          def build
            gem_cmd :build, gem.spec_filename
          end

          def push
            gem_cmd :push, gem.filename, *push_args
          end

          def tag
            Tag.new(context, args, opts).run
          end

          def github
            Github.new(context, args, opts).run
          end

          def push_args
            args = [:key, :host].map { |opt| ["--#{opt}", opts[opt]] if opts[opt] }
            args << "--quiet" if quiet?
            args.compact.flatten
          end

          def cleanup
            cmd :cleanup, gem.filename
          end

          def target_version
            opts[:version] || gem.version
          end
      end
    end
  end
end
