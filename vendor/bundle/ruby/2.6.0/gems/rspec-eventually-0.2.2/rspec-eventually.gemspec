
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'rspec/eventually/version'

Gem::Specification.new do |spec|
  spec.name          = 'rspec-eventually'
  spec.version       = Rspec::Eventually::VERSION
  spec.authors       = ['Hawk Newton']
  spec.email         = ['hawk.newton@gmail.com']
  spec.summary       = 'Make your matchers match eventually'
  spec.description   = 'Enhances rspec DSL to include `eventually` and `eventually_not`'
  spec.homepage      = 'https://github.com/hawknewton/rspec-eventually'
  spec.license       = 'MIT'

  spec.files         = `git ls-files -z`.split("\x0")
  spec.executables   = spec.files.grep(%r{^bin\/}) { |f| File.basename(f) }
  spec.test_files    = spec.files.grep(%r{^(test|spec|features)\/})
  spec.require_paths = ['lib']

  spec.add_development_dependency 'bundler', '~> 1.7'
  spec.add_development_dependency 'rake', '~> 10.0'
  spec.add_development_dependency 'rspec', '~> 3.2'
  spec.add_development_dependency 'rubocop', '~> 0.52'
end
