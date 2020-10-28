# -*- encoding: utf-8 -*-
# stub: rubocop-mhenrixon 0.81.0 ruby lib

Gem::Specification.new do |s|
  s.name = "rubocop-mhenrixon".freeze
  s.version = "0.81.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "changelog_uri" => "https://github.com/mhenrixon/rubocop-mhenrixon", "homepage_uri" => "https://github.com/mhenrixon/rubocop-mhenrixon", "source_code_uri" => "https://github.com/mhenrixon/rubocop-mhenrixon" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["mhenrixon".freeze]
  s.date = "2020-04-06"
  s.description = "Convenience gem to handle my rubocop configuration in multiple projects.".freeze
  s.email = ["mikael@mhenrixon.com".freeze]
  s.homepage = "https://github.com/mhenrixon/rubocop-mhenrixon".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Shared rubocop configuration for open source gems.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<rubocop>.freeze, ["~> 0.81.0"])
      s.add_runtime_dependency(%q<rubocop-performance>.freeze, ["~> 1.5"])
      s.add_runtime_dependency(%q<rubocop-rake>.freeze, ["~> 0.5"])
      s.add_runtime_dependency(%q<rubocop-rspec>.freeze, ["~> 1.37"])
      s.add_runtime_dependency(%q<rubocop-thread_safety>.freeze, ["~> 0.3"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 2.1"])
      s.add_development_dependency(%q<gem-release>.freeze, ["~> 2.1"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.9"])
    else
      s.add_dependency(%q<rubocop>.freeze, ["~> 0.81.0"])
      s.add_dependency(%q<rubocop-performance>.freeze, ["~> 1.5"])
      s.add_dependency(%q<rubocop-rake>.freeze, ["~> 0.5"])
      s.add_dependency(%q<rubocop-rspec>.freeze, ["~> 1.37"])
      s.add_dependency(%q<rubocop-thread_safety>.freeze, ["~> 0.3"])
      s.add_dependency(%q<bundler>.freeze, ["~> 2.1"])
      s.add_dependency(%q<gem-release>.freeze, ["~> 2.1"])
      s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.9"])
    end
  else
    s.add_dependency(%q<rubocop>.freeze, ["~> 0.81.0"])
    s.add_dependency(%q<rubocop-performance>.freeze, ["~> 1.5"])
    s.add_dependency(%q<rubocop-rake>.freeze, ["~> 0.5"])
    s.add_dependency(%q<rubocop-rspec>.freeze, ["~> 1.37"])
    s.add_dependency(%q<rubocop-thread_safety>.freeze, ["~> 0.3"])
    s.add_dependency(%q<bundler>.freeze, ["~> 2.1"])
    s.add_dependency(%q<gem-release>.freeze, ["~> 2.1"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.9"])
  end
end
