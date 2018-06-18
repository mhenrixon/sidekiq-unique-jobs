# frozen_string_literal: true

require_relative 'version_check'

RSpec.configure do |config|
  config.before do |example|
    if (ruby_ver = example.metadata[:ruby_ver])
      check = VersionCheck.new(RUBY_VERSION, ruby_ver)
      check.invalid? do |operator_1, version_1, operator_2, version_2|
        skip("Ruby (#{RUBY_VERSION}) should be #{operator_1} #{version_1} AND #{operator_2} #{version_2}")
      end
    end
  end
end
