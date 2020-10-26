# frozen_string_literal: true

RSpec.configure do |config|
  config.before do |example|
    if (ruby_ver = example.metadata[:ruby_ver])
      unless SidekiqUniqueJobs::VersionCheck.satisfied?(RUBY_VERSION, ruby_ver) # rubocop:disable Style/SoleNestedConditional
        skip("Ruby (#{RUBY_VERSION}) should be #{ruby_ver}")
      end
    end
  end
end
