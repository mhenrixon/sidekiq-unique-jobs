require 'gem/release/cmds/base'
require 'gem/release/data'
require 'gem/release/files/template'

module Gem
  module Release
    module Cmds
      class Gemspec < Base
        summary 'Generates a gemspec.'

        description <<-str.split("\n").map(&:lstrip).join("\n")
          #{summary}

          If no argument is given the current directory name is used as the gem name. If
          one or many arguments are given then these will be used as gem names, and new
          directories will be created accordingly.

          The generated `gemspec` file will use the `glob` strategy for finding files by
          default. Known strategies are:

          * `glob` - uses the glob pattern `{bin/*,lib/**/*,[A-Z]*}`
          * `git`  - uses the git command `git ls-files app lib`
        str

        arg :gem_name, 'name of the gem (optional, will default to the current directory name if not specified)'

        DEFAULTS = {
          strategy: :glob
        }.freeze

        DESCR = {
          bin:      'Add bin files directive to the gemspec (defaults to true if a ./bin directory exists)',
          dir:      'Directory to place the gem in (defaults to the given name, or the current working dir)',
          license:  'License(s) to list in the gemspec',
          strategy: 'Strategy for collecting files [glob|git] in gemspec'
        }.freeze

        opt '--[no]-bin', descr(:bin) do |value|
          opts[:bin] = value
        end

        opt '--dir DIR', descr(:dir) do |value|
          opts[:dir] = value
        end

        opt '-l', '--[no-]license NAMES', descr(:license) do |value|
          value ? (opts[:license] ||= []) << value : opts[:license] = []
        end

        opt '-s', '--strategy', descr(:strategy) do |value|
          opts[:strategy] = value
        end

        MSGS = {
          gemspec: 'Generating %s.gemspec',
          create:  'Creating %s',
          exists:  'Skipping %s: already exists'
        }.freeze

        def run
          in_dirs do
            announce :gemspec, gem.name
            generate
          end
        end

        private

          def generate
            msg   = :create if pretend?
            msg ||= file.write ? :create : :exists
            level = msg == :create ? :notice : :warn
            send(level, msg, file.target)
          end

          def file
            templates["#{gem.name}.gemspec"]
          end

          def templates
            Files::Templates.new(['gemspec'], opts[:template], data)
          end

          def data
            Data.new(git, gem, opts).data
          end
      end
    end
  end
end
