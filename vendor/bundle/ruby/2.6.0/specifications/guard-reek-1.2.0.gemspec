# -*- encoding: utf-8 -*-
# stub: guard-reek 1.2.0 ruby lib

Gem::Specification.new do |s|
  s.name = "guard-reek".freeze
  s.version = "1.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Grant Petersen-Speelman".freeze, "Gustavo Villalta".freeze]
  s.date = "2017-06-16"
  s.description = "Guard::Reek automatically runs Reek when files change".freeze
  s.email = ["grant@my-grocery-price-book.co.za".freeze, "gvillalta99@gmail.com".freeze]
  s.homepage = "https://github.com/grantspeelman/guard-reek".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Guard plugin for Reek".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<reek>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<guard-compat>.freeze, ["~> 1.1"])
      s.add_development_dependency(%q<listen>.freeze, ["~> 3.0.8"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_development_dependency(%q<guard-rspec>.freeze, [">= 0"])
      s.add_development_dependency(%q<guard-bundler>.freeze, [">= 0"])
      s.add_development_dependency(%q<simplecov>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
    else
      s.add_dependency(%q<reek>.freeze, [">= 0"])
      s.add_dependency(%q<guard-compat>.freeze, ["~> 1.1"])
      s.add_dependency(%q<listen>.freeze, ["~> 3.0.8"])
      s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
      s.add_dependency(%q<guard-rspec>.freeze, [">= 0"])
      s.add_dependency(%q<guard-bundler>.freeze, [">= 0"])
      s.add_dependency(%q<simplecov>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<reek>.freeze, [">= 0"])
    s.add_dependency(%q<guard-compat>.freeze, ["~> 1.1"])
    s.add_dependency(%q<listen>.freeze, ["~> 3.0.8"])
    s.add_dependency(%q<bundler>.freeze, ["~> 1.3"])
    s.add_dependency(%q<guard-rspec>.freeze, [">= 0"])
    s.add_dependency(%q<guard-bundler>.freeze, [">= 0"])
    s.add_dependency(%q<simplecov>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
  end
end
