# -*- encoding: utf-8 -*-
# stub: simplecov-oj 0.18.4 ruby lib

Gem::Specification.new do |s|
  s.name = "simplecov-oj".freeze
  s.version = "0.18.4"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/mhenrixon/mhenrixon/issues", "changelog_uri" => "https://github.com/mhenrixon/simplecov-oj/CHANGELOG.md", "documentation_uri" => "https://mhenrixon.github.io/simplecov-oj", "homepage_uri" => "https://github.com/mhenrixon/simplecov-oj", "source_code_uri" => "https://github.com/mhenrixon/simplecov-oj" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mikael Henriksson".freeze]
  s.date = "2020-02-14"
  s.description = "Oj formatter for SimpleCov code coverage tool for ruby 2.4+\n".freeze
  s.email = ["mikael@mhenrixon.com".freeze]
  s.homepage = "https://github.com/mhenrixon/simplecov-oj".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Oj formatter for SimpleCov code coverage tool for ruby 2.4+".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<oj>.freeze, [">= 2.0", "< 5.0"])
      s.add_runtime_dependency(%q<simplecov>.freeze, ["~> 0.14", "< 1.0"])
      s.add_development_dependency(%q<appraisal>.freeze, [">= 0"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 2.1"])
      s.add_development_dependency(%q<gem-release>.freeze, ["~> 2.0"])
      s.add_development_dependency(%q<json_spec>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 13.0"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.9"])
      s.add_development_dependency(%q<github-markup>.freeze, ["~> 3.0"])
      s.add_development_dependency(%q<github_changelog_generator>.freeze, ["~> 1.14"])
      s.add_development_dependency(%q<yard>.freeze, ["~> 0.9"])
    else
      s.add_dependency(%q<oj>.freeze, [">= 2.0", "< 5.0"])
      s.add_dependency(%q<simplecov>.freeze, ["~> 0.14", "< 1.0"])
      s.add_dependency(%q<appraisal>.freeze, [">= 0"])
      s.add_dependency(%q<bundler>.freeze, ["~> 2.1"])
      s.add_dependency(%q<gem-release>.freeze, ["~> 2.0"])
      s.add_dependency(%q<json_spec>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.9"])
      s.add_dependency(%q<github-markup>.freeze, ["~> 3.0"])
      s.add_dependency(%q<github_changelog_generator>.freeze, ["~> 1.14"])
      s.add_dependency(%q<yard>.freeze, ["~> 0.9"])
    end
  else
    s.add_dependency(%q<oj>.freeze, [">= 2.0", "< 5.0"])
    s.add_dependency(%q<simplecov>.freeze, ["~> 0.14", "< 1.0"])
    s.add_dependency(%q<appraisal>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 2.1"])
    s.add_dependency(%q<gem-release>.freeze, ["~> 2.0"])
    s.add_dependency(%q<json_spec>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, ["~> 13.0"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.9"])
    s.add_dependency(%q<github-markup>.freeze, ["~> 3.0"])
    s.add_dependency(%q<github_changelog_generator>.freeze, ["~> 1.14"])
    s.add_dependency(%q<yard>.freeze, ["~> 0.9"])
  end
end
