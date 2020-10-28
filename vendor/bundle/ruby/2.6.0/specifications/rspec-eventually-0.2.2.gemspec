# -*- encoding: utf-8 -*-
# stub: rspec-eventually 0.2.2 ruby lib

Gem::Specification.new do |s|
  s.name = "rspec-eventually".freeze
  s.version = "0.2.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Hawk Newton".freeze]
  s.date = "2017-12-20"
  s.description = "Enhances rspec DSL to include `eventually` and `eventually_not`".freeze
  s.email = ["hawk.newton@gmail.com".freeze]
  s.homepage = "https://github.com/hawknewton/rspec-eventually".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Make your matchers match eventually".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<bundler>.freeze, ["~> 1.7"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2"])
      s.add_development_dependency(%q<rubocop>.freeze, ["~> 0.52"])
    else
      s.add_dependency(%q<bundler>.freeze, ["~> 1.7"])
      s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.2"])
      s.add_dependency(%q<rubocop>.freeze, ["~> 0.52"])
    end
  else
    s.add_dependency(%q<bundler>.freeze, ["~> 1.7"])
    s.add_dependency(%q<rake>.freeze, ["~> 10.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.2"])
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.52"])
  end
end
