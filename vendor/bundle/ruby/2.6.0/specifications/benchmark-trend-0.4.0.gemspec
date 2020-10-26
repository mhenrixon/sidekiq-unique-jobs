# -*- encoding: utf-8 -*-
# stub: benchmark-trend 0.4.0 ruby lib

Gem::Specification.new do |s|
  s.name = "benchmark-trend".freeze
  s.version = "0.4.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "bug_tracker_uri" => "https://github.com/piotrmurach/benchmark-trend/issues", "changelog_uri" => "https://github.com/piotrmurach/benchmark-trend/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/benchmark-trend", "homepage_uri" => "https://github.com/piotrmurach/benchmark-trend", "source_code_uri" => "https://github.com/piotrmurach/benchmark-trend" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Piotr Murach".freeze]
  s.date = "2020-03-07"
  s.description = "Benchmark::Trend will help you estimate the computational complexity of Ruby code by running it on inputs increasing in size, measuring their execution times, and then fitting these observations into a model that best predicts how a given Ruby code will scale as a function of growing workload.".freeze
  s.email = ["piotr@piotrmurach.com".freeze]
  s.extra_rdoc_files = ["README.md".freeze, "CHANGELOG.md".freeze, "LICENSE.txt".freeze]
  s.files = ["CHANGELOG.md".freeze, "LICENSE.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/piotrmurach/benchmark-trend".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.0.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Measure performance trends of Ruby code based on the input size distribution.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    else
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
  end
end
