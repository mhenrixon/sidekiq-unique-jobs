# -*- encoding: utf-8 -*-
# stub: gh 0.18.0 ruby lib

Gem::Specification.new do |s|
  s.name = "gh".freeze
  s.version = "0.18.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Konstantin Haase".freeze]
  s.date = "2020-06-25"
  s.description = "multi-layer client for the github api v3".freeze
  s.email = ["konstantin.mailinglists@googlemail.com".freeze]
  s.homepage = "https://github.com/travis-ci/gh".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "layered github client".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_development_dependency(%q<webmock>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<faraday>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<faraday_middleware>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<activesupport>.freeze, ["~> 5.0"])
      s.add_runtime_dependency(%q<multi_json>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<addressable>.freeze, ["~> 2.4"])
      s.add_runtime_dependency(%q<net-http-persistent>.freeze, ["~> 2.9"])
      s.add_runtime_dependency(%q<net-http-pipeline>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_dependency(%q<webmock>.freeze, [">= 0"])
      s.add_dependency(%q<faraday>.freeze, ["~> 1.0"])
      s.add_dependency(%q<faraday_middleware>.freeze, ["~> 1.0"])
      s.add_dependency(%q<activesupport>.freeze, ["~> 5.0"])
      s.add_dependency(%q<multi_json>.freeze, ["~> 1.0"])
      s.add_dependency(%q<addressable>.freeze, ["~> 2.4"])
      s.add_dependency(%q<net-http-persistent>.freeze, ["~> 2.9"])
      s.add_dependency(%q<net-http-pipeline>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<webmock>.freeze, [">= 0"])
    s.add_dependency(%q<faraday>.freeze, ["~> 1.0"])
    s.add_dependency(%q<faraday_middleware>.freeze, ["~> 1.0"])
    s.add_dependency(%q<activesupport>.freeze, ["~> 5.0"])
    s.add_dependency(%q<multi_json>.freeze, ["~> 1.0"])
    s.add_dependency(%q<addressable>.freeze, ["~> 2.4"])
    s.add_dependency(%q<net-http-persistent>.freeze, ["~> 2.9"])
    s.add_dependency(%q<net-http-pipeline>.freeze, [">= 0"])
  end
end
