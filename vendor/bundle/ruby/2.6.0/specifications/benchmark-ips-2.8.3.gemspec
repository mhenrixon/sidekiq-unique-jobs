# -*- encoding: utf-8 -*-
# stub: benchmark-ips 2.8.3 ruby lib

Gem::Specification.new do |s|
  s.name = "benchmark-ips".freeze
  s.version = "2.8.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "homepage_uri" => "https://github.com/evanphx/benchmark-ips" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Evan Phoenix".freeze]
  s.date = "2020-08-28"
  s.description = "An iterations per second enhancement to Benchmark.".freeze
  s.email = ["evan@phx.io".freeze]
  s.extra_rdoc_files = ["History.txt".freeze, "Manifest.txt".freeze, "README.md".freeze]
  s.files = ["History.txt".freeze, "Manifest.txt".freeze, "README.md".freeze]
  s.homepage = "https://github.com/evanphx/benchmark-ips".freeze
  s.licenses = ["MIT".freeze]
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "An iterations per second enhancement to Benchmark.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<minitest>.freeze, ["~> 5.14"])
      s.add_development_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
      s.add_development_dependency(%q<hoe>.freeze, ["~> 3.22"])
    else
      s.add_dependency(%q<minitest>.freeze, ["~> 5.14"])
      s.add_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
      s.add_dependency(%q<hoe>.freeze, ["~> 3.22"])
    end
  else
    s.add_dependency(%q<minitest>.freeze, ["~> 5.14"])
    s.add_dependency(%q<rdoc>.freeze, [">= 4.0", "< 7"])
    s.add_dependency(%q<hoe>.freeze, ["~> 3.22"])
  end
end
