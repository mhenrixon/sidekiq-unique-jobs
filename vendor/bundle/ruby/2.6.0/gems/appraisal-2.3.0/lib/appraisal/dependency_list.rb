require 'appraisal/dependency'

module Appraisal
  class DependencyList
    def initialize
      @dependencies = Hash.new
    end

    def add(name, requirements)
      @dependencies[name] = Dependency.new(name, requirements)
    end

    def to_s
      @dependencies.values.map(&:to_s).join("\n")
    end

    # :nodoc:
    def for_dup
      @dependencies.values.map(&:for_dup).join("\n")
    end
  end
end
