# frozen_string_literal: true

RSpec.configure do |config|
  config.before(:each) do |example|
    ruby_ver = example.metadata[:ruby_ver]
    VERSION_REGEX.match(ruby_ver.to_s) do |match|
      version  = Gem::Version.new(match[:version])
      operator = match[:operator]
      next unless ruby_ver

      raise 'Please specify how to compare the version with >= or < or =' unless operator

      unless Gem::Version.new(RUBY_VERSION).send(operator, version)
        skip("Skipped due to version check (requirement was that ruby version is " \
             "#{operator} #{version}; was #{RUBY_VERSION})")
      end
    end
  end
end
