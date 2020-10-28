# frozen_string_literal: true

lib = File.expand_path("lib", __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "simplecov-material/version"

Gem::Specification.new do |spec|
  spec.name          = "simplecov-material"
  spec.version       = SimpleCov::Formatter::MaterialFormatter::VERSION
  spec.authors       = ["Christopher Pezza"]
  spec.email         = ["chiefpansancolt@gmail.com"]
  spec.summary       = "HTML Material Design View for Simplecov formatter"
  spec.description   = "HTML Material Design View of Simplecov as a formatter"\
                       "that is clean, easy to read."
  spec.homepage      = "https://github.com/chiefpansancolt/simplecov-material"
  spec.license       = "MIT"

  spec.required_ruby_version = ">= 2.3.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/chiefpansancolt/simplecov-material"
  spec.metadata["changelog_uri"] = "https://github.com/chiefpansancolt/simplecov-material/blob/master/CHANGELOG.md"
  spec.metadata["bug_tracker_uri"] = "https://github.com/chiefpansancolt/simplecov-material/issues"

  spec.files         = `git ls-files`.split("\n")
  spec.bindir        = "bin"
  spec.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.executables   = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_dependency "simplecov", ">= 0.16.0"
end
