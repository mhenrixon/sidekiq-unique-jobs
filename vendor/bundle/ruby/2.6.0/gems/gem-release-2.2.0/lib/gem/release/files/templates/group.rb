module Gem
  module Release
    module Files
      class Templates
        class Group
          attr_reader :groups, :data, :sources, :files

          def initialize(groups, data, sources, files)
            @groups  = [:default] + Array(groups)
            @data    = data
            @sources = sources
            @files   = Array(files)
          end

          def all
            return [] unless paths.any?
            all = Dir.glob(pattern, File::FNM_DOTMATCH)
            all = all.select { |file| File.file?(file) }
            all.map { |file| [file, relative(file)] }
          end

          private

            def pattern
              pattern = "{#{paths.join(',')}}"
              pattern << "/{#{files.join(',')}}" if files.any?
              pattern
            end

            def relative(file)
              paths.inject(file) { |file, path| file.sub("#{path}/", '') }
            end

            def paths
              @paths ||= groups.map do |group|
                paths = paths_for(group).map { |path| File.expand_path(*path) }
                paths.detect { |path| File.exist?(path) }
              end.compact
            end

            def paths_for(group)
              sources.map { |paths| paths.map { |path| path % group } }
            end
        end
      end
    end
  end
end

