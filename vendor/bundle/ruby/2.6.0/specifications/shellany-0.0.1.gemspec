# -*- encoding: utf-8 -*-
# stub: shellany 0.0.1 ruby lib

Gem::Specification.new do |s|
  s.name = "shellany".freeze
  s.version = "0.0.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Cezary Baginski".freeze]
  s.date = "2014-12-25"
  s.description = "MRI+JRuby compatible command output capturing".freeze
  s.email = ["cezary@chronomantic.net".freeze]
  s.homepage = "".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Simple, somewhat portable command capturing".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.7"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.7"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.7"])
  end
end
