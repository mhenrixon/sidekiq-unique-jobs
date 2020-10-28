# -*- encoding: utf-8 -*-
# stub: stackprof 0.2.16 ruby lib
# stub: ext/stackprof/extconf.rb

Gem::Specification.new do |s|
  s.name = "stackprof".freeze
  s.version = "0.2.16"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.metadata = { "bug_tracker_uri" => "https://github.com/tmm1/stackprof/issues", "changelog_uri" => "https://github.com/tmm1/stackprof/blob/v0.2.16/CHANGELOG.md", "documentation_uri" => "https://www.rubydoc.info/gems/stackprof/0.2.16", "source_code_uri" => "https://github.com/tmm1/stackprof/tree/v0.2.16" } if s.respond_to? :metadata=
  s.require_paths = ["lib".freeze]
  s.authors = ["Aman Gupta".freeze]
  s.date = "2020-10-22"
  s.description = "stackprof is a fast sampling profiler for ruby code, with cpu, wallclock and object allocation samplers.".freeze
  s.email = "aman@tmm1.net".freeze
  s.executables = ["stackprof".freeze, "stackprof-flamegraph.pl".freeze, "stackprof-gprof2dot.py".freeze]
  s.extensions = ["ext/stackprof/extconf.rb".freeze]
  s.files = ["bin/stackprof".freeze, "bin/stackprof-flamegraph.pl".freeze, "bin/stackprof-gprof2dot.py".freeze, "ext/stackprof/extconf.rb".freeze]
  s.homepage = "http://github.com/tmm1/stackprof".freeze
  s.licenses = ["MIT".freeze]
  s.required_ruby_version = Gem::Requirement.new(">= 2.2".freeze)
  s.rubygems_version = "3.0.3".freeze
  s.summary = "sampling callstack-profiler for ruby 2.2+".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_development_dependency(%q<rake-compiler>.freeze, ["~> 0.9"])
      s.add_development_dependency(%q<mocha>.freeze, ["~> 0.14"])
      s.add_development_dependency(%q<minitest>.freeze, ["~> 5.0"])
    else
      s.add_dependency(%q<rake-compiler>.freeze, ["~> 0.9"])
      s.add_dependency(%q<mocha>.freeze, ["~> 0.14"])
      s.add_dependency(%q<minitest>.freeze, ["~> 5.0"])
    end
  else
    s.add_dependency(%q<rake-compiler>.freeze, ["~> 0.9"])
    s.add_dependency(%q<mocha>.freeze, ["~> 0.14"])
    s.add_dependency(%q<minitest>.freeze, ["~> 5.0"])
  end
end
