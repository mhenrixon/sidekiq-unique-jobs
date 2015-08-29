# -*- encoding: utf-8 -*-
require File.expand_path('../lib/sidekiq_unique_jobs/version', __FILE__)

Gem::Specification.new do |gem|
  gem.authors       = ['Mikael Henriksson']
  gem.email         = ['mikael@zoolutions.se']
  gem.description   = gem.summary = 'The unique jobs that were removed from sidekiq'
  gem.homepage      = 'https://github.com/mhenrixon/sidekiq-unique-jobs'
  gem.license       = 'LGPL-3.0'

  # gem.executables   = ['']
  gem.files         = `git ls-files`.split("\n")
  gem.test_files    = `git ls-files -- test/*`.split("\n")
  gem.name          = 'sidekiq-unique-jobs'
  gem.require_paths = ['lib']
  gem.post_install_message = 'If you are relying on `mock_redis` you will now have to add' \
                             'gem "mock_redis" to your desired bundler group.'
  gem.version = SidekiqUniqueJobs::VERSION
  gem.add_dependency 'sidekiq', '>= 2.6'
  gem.add_development_dependency 'mock_redis'
  gem.add_development_dependency 'rspec', '~> 3.1.0'
  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'rspec-sidekiq'
  gem.add_development_dependency 'activesupport', '>= 3'
  gem.add_development_dependency 'rubocop'
  gem.add_development_dependency 'simplecov'
end
