# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rubocop/thread_safety/version'

Gem::Specification.new do |spec|
  spec.name          = 'rubocop-thread_safety'
  spec.version       = RuboCop::ThreadSafety::VERSION
  spec.authors       = ['Michael Gee']
  spec.email         = ['michaelpgee@gmail.com']

  spec.summary       = 'Thread-safety checks via static analysis'
  spec.description   = <<-DESCRIPTION
    Thread-safety checks via static analysis.
    A plugin for the RuboCop code style enforcing & linting tool.
  DESCRIPTION
  spec.homepage = 'https://github.com/covermymeds/rubocop-thread_safety'
  spec.licenses = ['MIT']

  spec.files = `git ls-files -z`.split("\x0").reject do |f|
    f.match(%r{^(test|spec|features)/})
  end

  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_runtime_dependency 'rubocop', '>= 0.51.0'

  spec.add_development_dependency 'bundler', '>= 1.10', '< 3'
  spec.add_development_dependency 'powerpack', '~> 0.1'
  spec.add_development_dependency 'pry' unless ENV['CI']
  spec.add_development_dependency 'rake', '>= 10.0'
  spec.add_development_dependency 'rspec', '~> 3.0'
end
