# -*- encoding: utf-8 -*-
# stub: appraisal 2.3.0 ruby lib

Gem::Specification.new do |s|
  s.name = "appraisal".freeze
  s.version = "2.3.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Joe Ferris".freeze, "Prem Sichanugrist".freeze]
  s.date = "2020-06-05"
  s.description = "Appraisal integrates with bundler and rake to test your library against different versions of dependencies in repeatable scenarios called \"appraisals.\"".freeze
  s.email = ["jferris@thoughtbot.com".freeze, "prem@thoughtbot.com".freeze]
  s.executables = ["appraisal".freeze]
  s.files = ["bin/appraisal".freeze]
  s.homepage = "http://github.com/thoughtbot/appraisal".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Find out what your Ruby gems are worth".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rake>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<thor>.freeze, [">= 0.14.0"])
      s.add_development_dependency(%q<activesupport>.freeze, [">= 3.2.21"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    else
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
      s.add_dependency(%q<thor>.freeze, [">= 0.14.0"])
      s.add_dependency(%q<activesupport>.freeze, [">= 3.2.21"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
    s.add_dependency(%q<thor>.freeze, [">= 0.14.0"])
    s.add_dependency(%q<activesupport>.freeze, [">= 3.2.21"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
  end
end
