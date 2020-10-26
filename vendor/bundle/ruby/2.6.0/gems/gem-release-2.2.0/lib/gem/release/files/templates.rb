module Gem
  module Release
    module Files
      class Templates < Struct.new(:files, :groups, :data)
        BUILTIN = [
          ['./.gem-release/%s'],
          ['~/.gem-release/%s'],
          ['../../templates/', __FILE__],
        ]

        CUSTOM = [
          ['./.gem-release/%s'],
          ['~/.gem-release/%s'],
          ['../../templates/%s', __FILE__],
        ]

        EXECUTABLE = [
          ['./.gem-release/executable'],
          ['~/.gem-release/executable'],
          ['../../templates/executable', __FILE__],
        ]

        LICENSE = [
          ['./.gem-release/licenses'],
          ['~/.gem-release/licenses'],
          ['../../templates/licenses', __FILE__],
        ]

        def self.executable(target)
          file = Templates.new([".*"], [], {}).executable
          file.target = target if file
          file
        end

        def self.license(name, data)
          file = Templates.new(["#{name}{,.*}"], [], data).license
          file.target = "LICENSE#{File.extname(file.target)}" if file
          file
        end

        def [](filename)
          all.detect { |file| file.filename == filename }
        end

        def all
          all = builtin + custom
          all.flatten.uniq(&:target)
        end

        def builtin
          templates_for(BUILTIN, files)
        end

        def custom
          templates_for(CUSTOM, '**/*')
        end

        def executable
          templates_for(EXECUTABLE).first
        end

        def license
          templates_for(LICENSE, files).first
        end

        def templates_for(sources, files = nil, opts = {})
          all = Group.new(groups, data, sources, files).all
          all.map { |source, target| Template.new(source, target, data, opts) }
        end
      end
    end
  end
end

require 'gem/release/files/templates/group'
