# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rubocop/mhenrixon/version'

Gem::Specification.new do |spec|
  spec.name          = 'rubocop-mhenrixon'
  spec.version       = Rubocop::Mhenrixon::VERSION
  spec.authors       = ['mhenrixon']
  spec.email         = ['mikael@mhenrixon.com']

  spec.summary       = 'Shared rubocop configuration for open source gems.'
  spec.description   = 'Convenience gem to handle my rubocop configuration in multiple projects.'
  spec.homepage      = 'https://github.com/mhenrixon/rubocop-mhenrixon'
  spec.license       = 'MIT'

  if spec.respond_to?(:metadata)
    spec.metadata['allowed_push_host'] = 'https://rubygems.org'
    spec.metadata['homepage_uri'] = spec.homepage
    spec.metadata['source_code_uri'] = 'https://github.com/mhenrixon/rubocop-mhenrixon'
    spec.metadata['changelog_uri'] = 'https://github.com/mhenrixon/rubocop-mhenrixon'
  else
    raise 'RubyGems 2.0 or newer is required to protect against ' \
      'public gem pushes.'
  end

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files = Dir.chdir(File.expand_path(__dir__)) do
    `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features|bin)/}) }
  end
  spec.bindir        = 'bin'
  spec.executables   = spec.files.grep(%r{^bin/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'rubocop', '~> 0.81.0'
  spec.add_dependency 'rubocop-performance', '~> 1.5'
  spec.add_dependency 'rubocop-rake', '~> 0.5'
  spec.add_dependency 'rubocop-rspec', '~> 1.37'
  spec.add_dependency 'rubocop-thread_safety', '~> 0.3'

  spec.add_development_dependency 'bundler', '~> 2.1'
  spec.add_development_dependency 'gem-release', '~> 2.1'
  spec.add_development_dependency 'rake', '~> 13.0'
  spec.add_development_dependency 'rspec', '~> 3.9'
end
