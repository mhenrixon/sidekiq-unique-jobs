# -*- encoding: utf-8 -*-
# stub: rspec-benchmark 0.6.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rspec-benchmark".freeze
  s.version = "0.6.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/piotrmurach/rspec-benchmark/issues", "changelog_uri" => "https://github.com/piotrmurach/rspec-benchmark/blob/master/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/rspec-benchmark", "homepage_uri" => "https://github.com/piotrmurach/rspec-benchmark", "source_code_uri" => "https://github.com/piotrmurach/rspec-benchmark" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Piotr Murach".freeze]
  s.date = "2020-03-09"
  s.description = "Performance testing matchers for RSpec to set expectations on speed, resources usage and scalibility.".freeze
  s.email = ["piotr@piotrmurach.com".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "CHANGELOG.md".freeze, "LICENSE.txt".freeze]
  s.files = ["CHANGELOG.md".freeze, "LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/piotrmurach/rspec-benchmark".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.1.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Performance testing matchers for RSpec".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<benchmark-malloc>.freeze, ["~> 0.2"])
      s.add_runtime_dependency(%q<benchmark-perf>.freeze, ["~> 0.6"])
      s.add_runtime_dependency(%q<benchmark-trend>.freeze, ["~> 0.4"])
      s.add_runtime_dependency(%q<rspec>.freeze, [">= 3.0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    else
      s.add_dependency(%q<benchmark-malloc>.freeze, ["~> 0.2"])
      s.add_dependency(%q<benchmark-perf>.freeze, ["~> 0.6"])
      s.add_dependency(%q<benchmark-trend>.freeze, ["~> 0.4"])
      s.add_dependency(%q<rspec>.freeze, [">= 3.0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<benchmark-malloc>.freeze, ["~> 0.2"])
    s.add_dependency(%q<benchmark-perf>.freeze, ["~> 0.6"])
    s.add_dependency(%q<benchmark-trend>.freeze, ["~> 0.4"])
    s.add_dependency(%q<rspec>.freeze, [">= 3.0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
