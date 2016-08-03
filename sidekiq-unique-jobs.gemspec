# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sidekiq_unique_jobs/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Mikael Henriksson']
  gem.email         = ['mikael@zoolutions.se']
  gem.description   = gem.summary = 'The unique jobs that were removed from sidekiq'
  gem.homepage      = 'https://github.com/mhenrixon/sidekiq-unique-jobs'
  gem.license       = 'WTFPL-2.0'

  gem.executables   = %w(jobs)
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- test/*`.split("\n")
  gem.name          = 'sidekiq-unique-jobs'
  gem.require_paths = ['lib']
  gem.post_install_message = 'WARNING: VERSION 4.0.0 HAS BREAKING CHANGES! Please see Readme for info'
  gem.version = SidekiqUniqueJobs::VERSION
  gem.add_dependency 'sidekiq', '>= 2.6'
  gem.add_dependency 'thor', '>= 0'
  gem.add_development_dependency 'rspec', '~> 3.1'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'timecop'
  gem.add_development_dependency 'yard'
end
