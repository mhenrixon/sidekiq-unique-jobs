# encoding: utf-8

$:.unshift File.expand_path('../lib', __FILE__)
require 'gem/release/version'

Gem::Specification.new do |s|
  s.name         = 'gem-release'
  s.version      = Gem::Release::VERSION
  s.authors      = ['Sven Fuchs', 'Dan Gebhardt']
  s.email        = ['me@svenfuchs.com']
  s.homepage     = 'https://github.com/svenfuchs/gem-release'
  s.licenses     = ['MIT']
  s.summary      = 'Release your ruby gems with ease'
  s.description  = 'Release your ruby gems with ease. (What a bold statement for such a tiny plugin ...)'

  s.files        = Dir.glob('{bin/*,lib/**/*,[A-Z]*}', File::FNM_DOTMATCH)
  s.platform     = Gem::Platform::RUBY
  s.require_path = 'lib'
end
