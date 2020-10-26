require "appraisal/bundler_dsl"

module Appraisal
  autoload :Gemspec, "appraisal/gemspec"
  autoload :Git, "appraisal/git"
  autoload :Group, "appraisal/group"
  autoload :Path, "appraisal/path"
  autoload :Platform, "appraisal/platform"
  autoload :Source, "appraisal/source"

  # Load bundler Gemfiles and merge dependencies
  class Gemfile < BundlerDSL
    def load(path)
      if File.exist?(path)
        run(IO.read(path))
      end
    end

    def run(definitions)
      instance_eval(definitions, __FILE__, __LINE__) if definitions
    end

    def dup
      Gemfile.new.tap do |gemfile|
        gemfile.git_sources = @git_sources
        gemfile.run(for_dup)
      end
    end
  end
end
