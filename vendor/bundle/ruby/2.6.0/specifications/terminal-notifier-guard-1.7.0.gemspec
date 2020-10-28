# -*- encoding: utf-8 -*-
# stub: terminal-notifier-guard 1.7.0 ruby lib

Gem::Specification.new do |s|
  s.name = "terminal-notifier-guard".freeze
  s.version = "1.7.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Eloy Duran".freeze, "Wouter de Vos".freeze]
  s.date = "2016-02-20"
  s.email = ["wouter@springest.com".freeze]
  s.extra_rdoc_files = ["README.markdown".freeze]
  s.files = ["README.markdown".freeze]
  s.homepage = "https://github.com/Springest/terminal-notifier-guard".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Send User Notifications on Mac OS X 10.8 - with status icons.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<bacon>.freeze, [">= 0"])
      s.add_development_dependency(%q<mocha>.freeze, [">= 0"])
      s.add_development_dependency(%q<mocha-on-bacon>.freeze, [">= 0"])
    else
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<bacon>.freeze, [">= 0"])
      s.add_dependency(%q<mocha>.freeze, [">= 0"])
      s.add_dependency(%q<mocha-on-bacon>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<bacon>.freeze, [">= 0"])
    s.add_dependency(%q<mocha>.freeze, [">= 0"])
    s.add_dependency(%q<mocha-on-bacon>.freeze, [">= 0"])
  end
end
