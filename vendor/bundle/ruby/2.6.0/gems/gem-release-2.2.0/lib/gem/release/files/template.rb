require 'gem/release/files/template/context'

module Gem
  module Release
    module Files
      class Template
        FILES = {
          '.gitignore' => '.gitignore',
          'Gemfile'    => 'Gemfile',
          'gemspec'    => '%{gem_name}.gemspec',
          'license'    => 'MIT-LICENSE.md',
          'main.rb'    => 'lib/%{gem_path}.rb',
          'version.rb' => 'lib/%{gem_path}/version.rb'
        }.freeze

        attr_accessor :source, :target, :data, :opts

        def initialize(source, target, data, opts)
          @source = source
          @target = (FILES[target] || target) % data
          @data   = data
          @opts   = opts
        end

        PATH = File.expand_path('../..', __FILE__)

        def filename
          File.basename(target)
        end

        def write
          return false if exists?
          FileUtils.mkdir_p(File.dirname(target))
          File.write(target, render)
          FileUtils.chmod('+x', target) if opts[:executable]
          true
        end

        def exists?
          File.exist?(target.to_s)
        end

        private

          def render
            template.result(binding)
          end

          def template
            ERB.new(File.read(source))
          end

          def binding
            context.instance_eval { binding }
          end

          def context
            Context.new(data)
          end
      end
    end
  end
end
