require File.expand_path("../lib/toxiproxy/version", __FILE__)

Gem::Specification.new do |spec|
  spec.name = "toxiproxy"
  spec.version = Toxiproxy::VERSION
  spec.authors = ["Simon Eskildsen", "Jacob Wirth"]
  spec.email = "simon.eskildsen@shopify.com"
  spec.summary = "Ruby library for Toxiproxy"
  spec.description = "A Ruby library for controlling Toxiproxy. Can be used in resiliency testing."
  spec.homepage = "https://github.com/Shopify/toxiproxy"
  spec.license = "MIT"

  spec.files = `git ls-files`.split("\n")
  spec.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "minitest"
  spec.add_development_dependency "rake"
  spec.add_development_dependency "webmock"
end
