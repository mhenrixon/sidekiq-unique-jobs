# -*- encoding: utf-8 -*-
# stub: fasterer 0.8.3 ruby lib

Gem::Specification.new do |s|
  s.name = "fasterer".freeze
  s.version = "0.8.3"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Damir Svrtan".freeze]
  s.date = "2020-04-05"
  s.description = "Use Fasterer to check various places in your code that could be faster.".freeze
  s.email = ["damir.svrtan@gmail.com".freeze]
  s.executables = ["fasterer".freeze]
  s.files = ["bin/fasterer".freeze]
  s.homepage = "https://github.com/DamirSvrtan/fasterer".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new("~> 2.2".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Run Ruby more than fast. Fasterer".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<colorize>.freeze, ["~> 0.7"])
      s.add_runtime_dependency(%q<ruby_parser>.freeze, [">= 3.14.1"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 1.6"])
      s.add_development_dependency(%q<pry>.freeze, ["~> 0.10"])
      s.add_development_dependency(%q<rake>.freeze, [">= 12.3.3"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.2"])
      s.add_development_dependency(%q<simplecov>.freeze, ["~> 0.9"])
    else
      s.add_dependency(%q<colorize>.freeze, ["~> 0.7"])
      s.add_dependency(%q<ruby_parser>.freeze, [">= 3.14.1"])
      s.add_dependency(%q<bundler>.freeze, [">= 1.6"])
      s.add_dependency(%q<pry>.freeze, ["~> 0.10"])
      s.add_dependency(%q<rake>.freeze, [">= 12.3.3"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.2"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.9"])
    end
  else
    s.add_dependency(%q<colorize>.freeze, ["~> 0.7"])
    s.add_dependency(%q<ruby_parser>.freeze, [">= 3.14.1"])
    s.add_dependency(%q<bundler>.freeze, [">= 1.6"])
    s.add_dependency(%q<pry>.freeze, ["~> 0.10"])
    s.add_dependency(%q<rake>.freeze, [">= 12.3.3"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.2"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.9"])
  end
end
