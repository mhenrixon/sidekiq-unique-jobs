require 'yaml'
require 'gem/release/helper/hash'

module Gem
  module Release
    class Config
      class Files
        include Helper::Hash

        PATHS = %w(
          ./.gem_release/config.yml
          ./.gem_release.yml
          ~/.gem_release/config.yml
          ~/.gem_release.yml
        )

        def load
          return {} unless path
          symbolize_keys(YAML.load_file(path) || {})
        end

        private

          def path
            @path ||= paths.first
          end

          def paths
            paths = PATHS.map { |path| File.expand_path(path) }
            paths.select { |path| File.exist?(path) }
          end
      end
    end
  end
end
