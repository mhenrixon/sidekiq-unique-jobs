require 'pathname'

module Gem
  module Release
    class Context
      class Paths < Struct.new(:names, :opts)
        class Base < Struct.new(:names, :opts)
          def in_dir(dir, &block)
            dir == cwd ? yield : Dir.chdir(dir, &block)
          end

          def current
            [[cwd, cwd.basename.to_s]]
          end

          def cwd
            @cwd ||= Pathname.pwd
          end
        end

        class ByNames < Base
          def in_dirs(&block)
            dirs.each do |dir, name|
              dir.mkdir unless dir == cwd || dir.exist?
              in_dir(dir) { yield name }
            end
          end

          private

            def dirs
              names.any? ? dirs_by_names : current
            end

            def dirs_by_names
              names.map { |name| [Pathname.new(dir || name).expand_path, name] }
            end

            def dir
              opts[:dir]
            end
        end

        class ByGemspecs < Base
          def in_dirs(&block)
            dirs.each do |dir, name|
              in_dir(dir) { yield name }
            end
          end

          private

            def dirs
              dirs = by_gemspecs if opts[:recurse]
              dirs ||= by_names  if names.any?
              dirs ||= gemspec
              dirs || by_gemspecs || current
            end

            def by_gemspecs
              paths = gemspecs(true).map { |path| [path.dirname, name_for(path)] }
              paths unless paths.empty?
            end

            def by_names
              paths = names.map { |arg| by_gemspecs.detect { |_, name| name == arg } }.compact
              paths unless paths.empty?
            end

            def gemspec
              path = gemspecs.first
              [[path.expand_path.dirname, name_for(path)]] if path
            end

            def name_for(path)
              path.basename('.gemspec').to_s
            end

            def gemspecs(recurse = false)
              pattern = recurse ? '**/*.gemspec' : '*.gemspec'
              Pathname.glob(pattern).map(&:expand_path).sort
            end
        end
      end
    end
  end
end
