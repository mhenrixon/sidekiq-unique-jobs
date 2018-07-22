# frozen_string_literal: true

lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)

require 'sidekiq_unique_jobs/version'

Gem::Specification.new do |spec|
  spec.name          = 'sidekiq-unique-jobs'
  spec.version       = SidekiqUniqueJobs::VERSION
  spec.authors       = ['Mikael Henriksson']
  spec.email         = ['mikael@zoolutions.se']

  spec.summary       = 'Uniqueness for Sidekiq Jobs'
  spec.description   = 'Handles various types of unique jobs for Sidekiq'
  spec.homepage      = 'https://github.com/mhenrixon/sidekiq-unique-jobs'
  spec.license       = 'MIT'

  spec.bindir        = 'bin'
  spec.executables   = %w[uniquejobs]

  spec.files         = Dir.chdir(File.expand_path('..', __FILE__)) do
    `git ls-files -z`.split("\x0").reject do |file|
      file.match(%r{^(test|spec|features|gemfiles|pkg|rails_example|tmp)/})
    end
  end

  spec.require_paths = ['lib']
  spec.add_dependency 'concurrent-ruby', '~> 1.0', '>= 1.0.5'
  spec.add_dependency 'sidekiq', '>= 4.0', '< 6.0'
  spec.add_dependency 'thor', '~> 0'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'rspec', '~> 3.7'
  spec.add_development_dependency 'rake', '~> 12.3'
  spec.add_development_dependency 'timecop', '~> 0.9'
  spec.add_development_dependency 'yard', '~> 0.9'
  spec.add_development_dependency 'gem-release', '~> 1.0'
  spec.add_development_dependency 'awesome_print', '~> 1.8'
  spec.add_development_dependency 'rack-test'
end
