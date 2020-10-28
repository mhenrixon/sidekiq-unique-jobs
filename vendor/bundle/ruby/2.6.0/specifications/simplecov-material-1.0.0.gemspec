# -*- encoding: utf-8 -*-
# stub: simplecov-material 1.0.0 ruby lib

Gem::Specification.new do |s|
  s.name = "simplecov-material".freeze
  s.version = "1.0.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/chiefpansancolt/simplecov-material/issues", "changelog_uri" => "https://github.com/chiefpansancolt/simplecov-material/blob/master/CHANGELOG.md", "homepage_uri" => "https://github.com/chiefpansancolt/simplecov-material", "source_code_uri" => "https://github.com/chiefpansancolt/simplecov-material" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Christopher Pezza".freeze]
  s.date = "2020-10-09"
  s.description = "HTML Material Design View of Simplecov as a formatterthat is clean, easy to read.".freeze
  s.email = ["chiefpansancolt@gmail.com".freeze]
  s.executables = ["console".freeze, "publish".freeze, "setup".freeze]
  s.files = ["bin/console".freeze, "bin/publish".freeze, "bin/setup".freeze]
  s.homepage = "https://github.com/chiefpansancolt/simplecov-material".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "HTML Material Design View for Simplecov formatter".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<simplecov>.freeze, [">= 0.16.0"])
    else
      s.add_dependency(%q<simplecov>.freeze, [">= 0.16.0"])
    end
  else
    s.add_dependency(%q<simplecov>.freeze, [">= 0.16.0"])
  end
end
