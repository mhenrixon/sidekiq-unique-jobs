# frozen_string_literal: true

require_relative 'version_check'

RSpec.configure do |config|
  config.before do |example|
    if (ruby_ver = example.metadata[:ruby_ver])
      check = VersionCheck.new(RUBY_VERSION, ruby_ver)
      check.invalid? do |operator1, version1, operator2, version2|
        skip("Ruby (#{RUBY_VERSION}) should be #{operator1} #{version1} AND #{operator2} #{version2}")
      end
    end
  end
end
