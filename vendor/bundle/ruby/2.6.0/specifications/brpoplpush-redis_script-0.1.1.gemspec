# -*- encoding: utf-8 -*-
# stub: brpoplpush-redis_script 0.1.1 ruby lib

Gem::Specification.new do |s|
  s.name = "brpoplpush-redis_script".freeze
  s.version = "0.1.1"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "allowed_push_host" => "https://rubygems.org", "changelog_uri" => "https://github.com/brpoplpush/brpoplpush-redis_script/CHANGELOG.md", "homepage_uri" => "https://github.com/brpoplpush/brpoplpush-redis_script", "source_code_uri" => "https://github.com/brpoplpush/brpoplpush-redis_script" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Mikael Henriksson".freeze, "Mauro Berlanda".freeze]
  s.date = "2020-02-11"
  s.description = "Bring your own LUA scripts into redis.".freeze
  s.email = ["mikael@mhenrixon.com".freeze, "mauro.berlanda@gmail.com".freeze]
  s.homepage = "https://github.com/brpoplpush/brpoplpush-redis_script".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.5.0".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Bring your own LUA scripts into redis.".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0", ">= 1.0.5"])
      s.add_runtime_dependency(%q<redis>.freeze, [">= 1.0", "<= 5.0"])
      s.add_development_dependency(%q<bundler>.freeze, ["~> 2.0"])
      s.add_development_dependency(%q<rake>.freeze, ["~> 12.3"])
      s.add_development_dependency(%q<rspec>.freeze, ["~> 3.7"])
      s.add_development_dependency(%q<github-markup>.freeze, ["~> 3.0"])
      s.add_development_dependency(%q<github_changelog_generator>.freeze, ["~> 1.14"])
      s.add_development_dependency(%q<yard>.freeze, ["~> 0.9.18"])
      s.add_development_dependency(%q<gem-release>.freeze, ["~> 2.0"])
    else
      s.add_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0", ">= 1.0.5"])
      s.add_dependency(%q<redis>.freeze, [">= 1.0", "<= 5.0"])
      s.add_dependency(%q<bundler>.freeze, ["~> 2.0"])
      s.add_dependency(%q<rake>.freeze, ["~> 12.3"])
      s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
      s.add_dependency(%q<github-markup>.freeze, ["~> 3.0"])
      s.add_dependency(%q<github_changelog_generator>.freeze, ["~> 1.14"])
      s.add_dependency(%q<yard>.freeze, ["~> 0.9.18"])
      s.add_dependency(%q<gem-release>.freeze, ["~> 2.0"])
    end
  else
    s.add_dependency(%q<concurrent-ruby>.freeze, ["~> 1.0", ">= 1.0.5"])
    s.add_dependency(%q<redis>.freeze, [">= 1.0", "<= 5.0"])
    s.add_dependency(%q<bundler>.freeze, ["~> 2.0"])
    s.add_dependency(%q<rake>.freeze, ["~> 12.3"])
    s.add_dependency(%q<rspec>.freeze, ["~> 3.7"])
    s.add_dependency(%q<github-markup>.freeze, ["~> 3.0"])
    s.add_dependency(%q<github_changelog_generator>.freeze, ["~> 1.14"])
    s.add_dependency(%q<yard>.freeze, ["~> 0.9.18"])
    s.add_dependency(%q<gem-release>.freeze, ["~> 2.0"])
  end
end
