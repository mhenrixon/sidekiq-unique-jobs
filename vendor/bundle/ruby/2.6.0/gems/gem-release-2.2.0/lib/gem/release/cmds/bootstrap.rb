require 'gem/release/cmds/base'
require 'gem/release/data'
require 'gem/release/files/templates'

module Gem
  module Release
    module Cmds
      class Bootstrap < Base
        summary 'Scaffolds a new gem from template files.'

        description <<-str.split("\n").map(&:lstrip).join("\n")
          #{summary} Optionally initialize a git repository, set a git remote, and push
          to the remote repository.

          If no argument is given the current directory name is used as the gem name. If
          one or many arguments are given then these will be used as gem names, and new
          directories will be created accordingly.

          By default the following files will be created:

          * `.gitignore`
          * `Gemspec`
          * `[gem-name].gemspec`
          * `LICENSE.md`
          * `lib/[gem]/[name].rb`
          * `lib/[gem]/[name]/version.rb`

          Templates in the first existing one of these directories will always be used to
          create additional files:

          * `./.gem-release/default` (local)
          * `~/.gem-release/default` (global)

          If `--template [group]` is given additional files will be created from the
          first existing one of these directories:

          * `./.gem-release/[group]` (local)
          * `~/.gem-release/[group]` (global)

          It is possible to specify several template groups in order to add files from
          several custom template directories.

          If `--template rspec` is given then additionally the files `.rspec` and
          `spec/spec_helper.rb` will be created, or whatever files exist in a local or
          global directory `.gem-release/templates/rspec`.

          If `--template travis` is given then additionally the file `.travis.yml` will
          be created, or whatever files exist in a local or global directory
          `.gem-release/templates/travis`.

          The license added by default is the MIT License. If `--license [name]` is given
          then this license will be added. The only other license file shipped is the
          Mozilla Public License v2.0. Other licenses must be present in the local or
          global directory `.gem-release/licenses`. If `--no-license` is given then no
          license will be added.
        str

        arg :gem_name, 'name of the gem (optional, will default to the current directory name if not specified)'

        DEFAULTS = {
          strategy:  :glob,
          scaffold:  true,
          bin:       false,
          git:       true,
          github:    false,
          push:      false,
          license:   :mit,
          templates: []
        }.freeze

        DESCR = {
          scaffold: 'Scaffold gem files',
          dir:      'Directory to place the gem in (defaults to the given name, or the current working dir)',
          bin:      'Create an executable ./bin/[name], add executables directive to .gemspec',
          license:  'License(s) to add',
          template: 'Template groups to use for scaffolding',
          rspec:    'Use the rspec group (by default adds .rspec and spec/spec_helper.rb)',
          travis:   'Use the travis group (by default adds .travis.yml)',
          strategy: 'Strategy for collecting files [glob|git] in .gemspec',
          git:      'Initialize a git repo',
          github:   'Initialize a git repo, create on github',
          remote:   'Git remote repository',
          push:     'Push the git repo to github'
        }.freeze

        opt '--[no-]scaffold', descr(:scaffold) do |value|
          opts[:scaffold] = value
        end

        opt '--dir DIR', descr(:dir) do |value|
          opts[:dir] = value
        end

        opt '--bin', descr(:bin) do
          opts[:bin] = true
        end

        opt '-t', '--template NAME', descr(:template) do |value|
          (opts[:templates] ||= []) << value
        end

        opt '--rspec', descr(:rspec) do |value|
          (opts[:templates] ||= []) << :rspec
        end

        opt '--travis', descr(:travis) do |value|
          (opts[:templates] ||= []) << :travis
        end

        opt '-l', '--[no-]license NAME', descr(:license) do |value|
          opts[:license] = value
        end

        opt '-s', '--strategy NAME', descr(:strategy) do |value|
          opts[:strategy] = value
        end

        opt '--[no-]git', descr(:git) do |value|
          opts[:git] = value
        end

        opt '--github', descr(:github) do |value|
          opts[:github] = value
        end

        opt '--remote', descr(:remote) do |value|
          opts[:remote] = value
        end

        opt '--push', descr(:push) do |value|
          opts[:push] = value
        end

        MSGS = {
          scaffold:        'Scaffolding gem %s',
          create:          'Creating %s',
          exists:          'Skipping existing file %s',
          git_init:        'Initializing git repository',
          git_add:         'Adding files',
          git_commit:      'Creating initial commit',
          git_remote:      'Adding git remote %s',
          git_push:        'Pushing to git remote %s',
          unknown_license: 'Unknown license: %s'
        }.freeze

        CMDS = {
          git_init:   'git init',
          git_add:    'git add .',
          git_commit: 'git commit -m "Initial commit"',
          git_remote: 'git remote add %s https://github.com/%s.git',
          git_push:   'git push -u %s master'
        }.freeze

        def run
          in_dirs do
            scaffold    if opts[:scaffold]
            init_git    if opts[:github] || opts[:git]
            create_repo if opts[:github]
          end
        end

        private

          FILES = %w(
            .gitignore
            Gemfile
            gemspec
            main.rb
            version.rb
          )

          def scaffold
            announce :scaffold, gem.name
            files.each { |file| write(file) }
          end

          def files
            files = Files::Templates.new(FILES, opts[:templates], data).all
            files << executable if opts[:bin]
            files << license if opts[:license]
            files.compact
          end

          def executable
            Files::Templates.executable("bin/#{gem.name}")
          end

          def license
            file = Files::Templates.license(opts[:license], data)
            warn :unknown_license, opts[:license] unless file
            file
          end

          def write(file)
            msg   = :create if pretend?
            msg ||= file.write ? :create : :exists
            level = msg == :create ? :info : :warn
            send(level, msg, file.target)
          end

          def init_git
            cmd :git_init
            cmd :git_add
            cmd :git_commit
          end

          def create_repo
            cmd :git_remote, remote, "#{git.user_login}/#{gem.name}"
            cmd :git_push, remote if opts[:push]
          end

          def data
            Data.new(git, gem, opts).data
          end

          def remote
            opts[:remote] || :origin
          end

          def opts
            @opts ||= normalize(super)
          end

          def normalize(opts)
            opts[:templates] << 'rspec'  if opts.delete(:rspec)
            opts[:templates] << 'travis' if opts.delete(:travis)
            opts
          end
      end
    end
  end
end
