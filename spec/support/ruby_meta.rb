RSpec.configure do |config|
  config.before(:each) do |example|
    ruby_ver = example.metadata[:ruby_ver]
    next unless ruby_ver

    if Gem::Version.new(ruby_ver) >= Gem::Version.new(RUBY_VERSION)
      skip("Not relevant for version less than #{ruby_ver}")
    end
  end
end
