require 'gem/release/cmds/base'
require 'gem/release/files/version'

module Gem
  module Release
    module Cmds
      class Bump < Base
        summary 'Bumps one, several, or all gems in this directory.'

        description <<-str.split("\n").map(&:lstrip).join("\n")
          Bumps the version number defined in lib/[gem_name]/version.rb to to a given,
          specific version number, or to the next major, minor, patch, or pre-release
          level.

          Optionally it pushes to the origin repository. Also, optionally it invokes the
          `gem tag` and/or `gem release` command.

          If no argument is given the first gemspec's name is assumed as the gem name.
          If one or many arguments are given then these will be used as gem names. If
          `--recurse` is given then all gem names from all gemspecs in this directory or
          any of its subdirectories will be used.

          The version can be bumped to either one of these targets:

          ```
          major
          1.1.1       # Bump to the given, specific version number
          major       # Bump to the next major level (e.g. 0.0.1 to 1.0.0)
          minor       # Bump to the next minor level (e.g. 0.0.1 to 0.1.0)
          patch       # Bump to the next patch level (e.g. 0.0.1 to 0.0.2)
          pre|rc|etc  # Bump to the next pre-release level (e.g. 0.0.1 to
                      #   0.1.0.pre.1, 1.0.0.pre.1 to 1.0.0.pre.2)
          ```

          When searching for the version file for a gem named `gem-name`: the following
          paths will be searched relative to the gemspec's directory.

          * `lib/gem-name/version.rb`
          * `lib/gem/name/version.rb`
        str

        arg :gem_name, 'name of the gem (optional, will use the directory name, or all gemspecs if --recurse is given)'

        DESCR = {
          version: 'Target version: next [major|minor|patch|pre|release] or a given version number [x.x.x]',
          branch:  'Check out a new branch for the target version (e.g. `v1.0.0`)',
          commit:  'Create a commit after incrementing gem version',
          message: 'Commit message template',
          skip_ci: 'Add the [skip ci] tag to the commit message',
          push:    'Push the new commit to the git remote repository',
          remote:  'Git remote to push to (defaults to origin)',
          sign:    'GPG sign the commit message',
          tag:     'Shortcut for running the `gem tag` command',
          recurse: 'Recurse into directories that contain gemspec files',
          release: 'Shortcut for the `gem release` command',
          file:    'Full path to the version file'
        }.freeze

        DEFAULTS = {
          commit:  true,
          message: 'Bump %{name} to %{version} %{skip_ci}',
          push:    false,
          branch:  false,
          remote:  'origin',
          skip_ci: false,
          sign:    false,
          recurse: false,
          pretend: false
        }.freeze

        opt '-v', '--version VERSION', descr(:version) do |value|
          opts[:version] = value
        end

        opt '-c', '--[no-]commit', descr(:commit) do |value|
          opts[:commit] = value
        end

        opt '-m', '--message MESSAGE', descr(:message) do |value|
          opts[:message] = value
        end

        opt '--skip-ci', descr(:skip_ci) do |value|
          opts[:skip_ci] = value
        end

        opt '-p', '--push', descr(:push) do |value|
          opts[:push] = value
        end

        opt '--remote REMOTE', descr(:remote) do |value|
          opts[:remote] = value
        end

        opt '-s', '--sign', descr(:sign) do |value|
          opts[:sign] = value
        end

        opt '--branch [BRANCH]', descr(:branch) do |value|
          opts[:branch] = value.nil? ? true : value
        end

        opt '-t', '--tag', descr(:tag) do |value|
          opts[:tag] = value
        end

        opt '-r', '--release', descr(:release) do |value|
          opts[:release] = value
        end

        opt '--recurse', descr(:recurse) do |value|
          opts[:recurse] = value
        end

        opt '--file FILE', descr(:file) do |value|
          opts[:file] = value
        end

        MSGS = {
          bump:          'Bumping %s from version %s to %s',
          version:       'Changing version in %s from %s to %s',
          git_add:       'Staging %s',
          git_checkout:  'Checking out branch %s',
          git_commit:    'Creating commit',
          git_push:      'Pushing to the %s git repository',
          git_dirty:     'Uncommitted changes found. Please commit or stash.',
          not_found:     'Ignoring %s. Version file %s not found.',
          no_git_remote: 'Cannot push to missing git remote %s.'
        }.freeze

        CMDS = {
          git_checkout: 'git checkout -b %s',
          git_add:      'git add %s',
          git_commit:   'git commit -m %p %s',
          git_push:     'git push %s'
        }.freeze

        def run
          new_version = nil
          in_gem_dirs do
            validate
            checkout if opts[:branch]
            bump
            new_version = version.to
            commit if opts[:commit]
            push   if opts[:commit] && opts[:push]
            reset
          end
          tag(new_version)     if opts[:tag]
          release(new_version) if opts[:release]
        end

        private

          def validate
            abort :git_dirty unless git.clean?
            abort :no_git_remote, remote if push? && !git.remotes.include?(remote.to_s)
            abort :not_found, gem.name, version.path || '?' unless version.exists?
          end

          def checkout
            cmd :git_checkout, branch
          end

          def bump
            announce :bump, gem.name, version.from, version.to
            return true if pretend?
            notice :version, version.path, version.from, version.to
            version.bump
          end

          def commit
            cmd :git_add, version.path
            cmd :git_commit, message.strip, opts[:sign] ? '-S' : ''
          end

          def push
            cmd :git_push, remote
          end

          def tag(new_version)
            Tag.new(context, args, opts.merge(version: new_version)).run
          end

          def release(new_version)
            Release.new(context, args, except(opts, :tag).merge(version: new_version)).run
          end

          def branch
            case opts[:branch]
            when ::String
              opts[:branch]
            when true
              "v#{version.to}"
            end
          end

          def message
            args = { name: gem.name, skip_ci: opts[:skip_ci] ? '[skip ci]' : '' }
            args = args.merge(version.to_h)
            opts[:message] % args
          end

          def version
            @version ||= Files::Version.new(gem.name, opts[:version], only(opts, :file))
          end

          def reset
            @version = nil
          end

          def push?
            opts[:push]
          end

          def remote
            opts[:remote]
          end
      end
    end
  end
end
