RSpec.configure do |config|
  VERSION_REGEX = /(?<operator>[<>=]+)?\s?(?<version>(\d+.?)+)/m.freeze
  config.before(:each) do |example|
    Sidekiq::Worker.clear_all
    if (sidekiq = example.metadata[:sidekiq])
      sidekiq = :fake if sidekiq == true
      Sidekiq::Testing.send("#{sidekiq}!")
    end

    sidekiq_ver = example.metadata[:sidekiq_ver]
    version, operator = VERSION_REGEX.match(sidekiq_ver.to_s) do |m|
      fail 'Please specify how to compare the version with >= or < or =' unless m[:operator]
      [m[:version], m[:operator]]
    end

    unless Sidekiq::VERSION.send(operator, version)
      skip("Not relevant for version #{version}")
    end if version && operator
  end

  config.after(:each) do |example|
    Sidekiq::Testing.disable! unless example.metadata[:sidekiq].nil?
  end
end
