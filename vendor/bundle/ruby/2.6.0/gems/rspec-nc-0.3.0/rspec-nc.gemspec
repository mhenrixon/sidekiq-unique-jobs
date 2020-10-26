# -*- encoding: utf-8 -*-
Gem::Specification.new do |gem|
  gem.name = 'rspec-nc'
  gem.version = '0.3.0'
  gem.authors = ['Odin Dutton']
  gem.email = ['odindutton@gmail.com']
  gem.description = 'https://github.com/twe4ked/rspec-nc'
  gem.summary = "RSpec formatter for Mountain Lion's Notification Center"
  gem.homepage = 'https://github.com/twe4ked/rspec-nc'
  gem.license = 'MIT'

  gem.add_dependency 'terminal-notifier', '>= 1.4'
  gem.add_dependency 'rspec', '>= 3'

  gem.add_development_dependency 'rake'
  gem.add_development_dependency 'wwtd'
  gem.add_development_dependency 'pry'

  gem.files = `git ls-files`.split($\)
  gem.test_files = gem.files.grep(%r{^(spec)/})
  gem.require_paths = ['lib']
end
