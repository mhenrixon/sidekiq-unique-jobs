# -*- encoding: utf-8 -*-
# stub: github_changelog_generator 1.15.2 ruby lib

Gem::Specification.new do |s|
  s.name = "github_changelog_generator".freeze
  s.version = "1.15.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Petr Korolev".freeze, "Olle Jonsson".freeze, "Marco Ferrari".freeze]
  s.date = "2020-04-07"
  s.description = "Changelog generation has never been so easy. Fully automate changelog generation - this gem generate changelog file based on tags, issues and merged pull requests from Github issue tracker.".freeze
  s.email = "sky4winder+github_changelog_generator@gmail.com".freeze
  s.executables = ["git-generate-changelog".freeze, "github_changelog_generator".freeze]
  s.files = ["bin/git-generate-changelog".freeze, "bin/github_changelog_generator".freeze]
  s.homepage = "https://github.com/github-changelog-generator/Github-Changelog-Generator".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.3.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Script, that automatically generate changelog from your tags, issues, labels and pull requests.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<faraday-http-cache>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<multi_json>.freeze, [">= 0"])
      s.add_runtime_dependency(%q<octokit>.freeze, ["~> 4.6"])
      s.add_runtime_dependency(%q<rainbow>.freeze, [">= 2.2.1"])
      s.add_runtime_dependency(%q<rake>.freeze, [">= 10.0"])
      s.add_runtime_dependency(%q<retriable>.freeze, ["~> 3.0"])
    else
      s.add_dependency(%q<activesupport>.freeze, [">= 0"])
      s.add_dependency(%q<faraday-http-cache>.freeze, [">= 0"])
      s.add_dependency(%q<multi_json>.freeze, [">= 0"])
      s.add_dependency(%q<octokit>.freeze, ["~> 4.6"])
      s.add_dependency(%q<rainbow>.freeze, [">= 2.2.1"])
      s.add_dependency(%q<rake>.freeze, [">= 10.0"])
      s.add_dependency(%q<retriable>.freeze, ["~> 3.0"])
    end
  else
    s.add_dependency(%q<activesupport>.freeze, [">= 0"])
    s.add_dependency(%q<faraday-http-cache>.freeze, [">= 0"])
    s.add_dependency(%q<multi_json>.freeze, [">= 0"])
    s.add_dependency(%q<octokit>.freeze, ["~> 4.6"])
    s.add_dependency(%q<rainbow>.freeze, [">= 2.2.1"])
    s.add_dependency(%q<rake>.freeze, [">= 10.0"])
    s.add_dependency(%q<retriable>.freeze, ["~> 3.0"])
  end
end
