# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sidekiq-unique-jobs/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ["Mikael Henriksson"]
  gem.email         = ["mikael@zoolutions.se"]
  gem.description   = gem.summary = "The unique jobs that were removed from sidekiq"
  gem.homepage      = "http://mperham.github.com/sidekiq"
  gem.license       = "LGPL-3.0"

  # gem.executables   = ['']
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- test/*`.split("\n")
  gem.name          = "sidekiq-unique-jobs"
  gem.require_paths = ["lib"]
  gem.version       = SidekiqUniqueJobs::VERSION
  gem.add_dependency                  'sidekiq', '~> 2.6'
  gem.add_development_dependency      'minitest', '~> 3'
  gem.add_development_dependency      'sinatra'
  gem.add_development_dependency      'slim'
  gem.add_development_dependency      'rake'
  gem.add_development_dependency      'activesupport', '~> 3'
  gem.add_development_dependency      'simplecov'
end