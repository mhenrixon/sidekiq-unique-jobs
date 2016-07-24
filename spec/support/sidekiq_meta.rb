RSpec.configure do |config|
  VERSION_REGEX = /(?<operator>[<>=]+)?\s?(?<version>(\d+.?)+)/m
  config.before(:each) do |example|
    if (sidekiq = example.metadata[:sidekiq])
      sidekiq = :fake if sidekiq == true
      Sidekiq::Testing.send("#{sidekiq}!")
    end

    if (sidekiq_ver = example.metadata[:sidekiq_ver])
      VERSION_REGEX.match(sidekiq_ver.to_s) do |match|
        version  = match[:version]
        operator = match[:operator]

        raise 'Please specify how to compare the version with >= or < or =' unless operator

        unless Sidekiq::VERSION.send(operator, version)
          skip('Skipped due to version check (requirement was that sidekiq version is ' \
               "#{operator} #{version}; was #{Sidekiq::VERSION})")
        end
      end
    end
  end

  config.after(:each) do |example|
    Sidekiq::Testing.disable! unless example.metadata[:sidekiq].nil?
  end
end
