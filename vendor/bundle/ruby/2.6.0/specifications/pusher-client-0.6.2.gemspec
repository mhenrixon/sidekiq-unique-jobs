# -*- encoding: utf-8 -*-
# stub: pusher-client 0.6.2 ruby lib

Gem::Specification.new do |s|
  s.name = "pusher-client".freeze
  s.version = "0.6.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Pusher".freeze, "Logan Koester".freeze]
  s.date = "2015-05-14"
  s.description = "Client for consuming WebSockets from http://pusher.com".freeze
  s.email = ["support@pusher.com".freeze]
  s.extra_rdoc_files = ["LICENSE.txt".freeze, "README.rdoc".freeze]
  s.files = ["LICENSE.txt".freeze, "README.rdoc".freeze]
  s.homepage = "http://github.com/pusher/pusher-ruby-client".freeze
  s.licenses = ["MIT".freeze]
  s.rubygems_version = "3.0.3".freeze
  s.summary = "Client for consuming WebSockets from http://pusher.com".freeze

  s.installed_by_version = "3.0.3" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 4

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<websocket>.freeze, ["~> 1.0"])
      s.add_runtime_dependency(%q<json>.freeze, [">= 0"])
      s.add_development_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_development_dependency(%q<rake>.freeze, [">= 0"])
      s.add_development_dependency(%q<bundler>.freeze, [">= 0"])
    else
      s.add_dependency(%q<websocket>.freeze, ["~> 1.0"])
      s.add_dependency(%q<json>.freeze, [">= 0"])
      s.add_dependency(%q<rspec>.freeze, [">= 0"])
      s.add_dependency(%q<rake>.freeze, [">= 0"])
      s.add_dependency(%q<bundler>.freeze, [">= 0"])
    end
  else
    s.add_dependency(%q<websocket>.freeze, ["~> 1.0"])
    s.add_dependency(%q<json>.freeze, [">= 0"])
    s.add_dependency(%q<rspec>.freeze, [">= 0"])
    s.add_dependency(%q<rake>.freeze, [">= 0"])
    s.add_dependency(%q<bundler>.freeze, [">= 0"])
  end
end
