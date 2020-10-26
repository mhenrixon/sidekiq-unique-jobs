require 'gem/release/context/gemspec'

module Gem
  module Release
    class Context
      class Gem
        attr_reader :name, :spec

        def initialize(name)
          @spec = Gemspec.new(name)
          @name = name
        end

        def version
          spec.version.to_s if spec
        end

        def filename
          spec.gem_filename if spec
        end

        def spec_filename
          spec.filename if name
        end
      end
    end
  end
end
