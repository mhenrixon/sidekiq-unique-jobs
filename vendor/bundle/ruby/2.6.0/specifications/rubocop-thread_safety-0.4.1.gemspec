# -*- encoding: utf-8 -*-
# stub: rubocop-thread_safety 0.4.1 ruby lib

Gem::Specification.new do |s|
  s.name = "rubocop-thread_safety".freeze
  s.version = "0.4.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Michael Gee".freeze]
  s.bindir = "exe".freeze
  s.date = "2020-06-26"
  s.description = "    Thread-safety checks via static analysis.\n    A plugin for the RuboCop code style enforcing & linting tool.\n".freeze
  s.email = ["michaelpgee@gmail.com".freeze]
  s.homepage = "https://github.com/covermymeds/rubocop-thread_safety".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Thread-safety checks via static analysis".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rubocop>.freeze, [">= 0.51.0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 1.10", "< 3"])
      s.add_development_dependency(%q<powerpack>.freeze, ["~> 0.1"])
      s.add_development_dependency(%q<pry>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 10.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.0"])
    else
      s.add_dependency(%q<rubocop>.freeze, [">= 0.51.0"])
      s.add_dependency(%q<bundler>.freeze, [">= 1.10", "< 3"])
      s.add_dependency(%q<powerpack>.freeze, ["~> 0.1"])
      s.add_dependency(%q<pry>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 10.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<rubocop>.freeze, [">= 0.51.0"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.10", "< 3"])
    s.add_dependency(%q<powerpack>.freeze, ["~> 0.1"])
    s.add_dependency(%q<pry>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 10.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.0"])
  end
end
