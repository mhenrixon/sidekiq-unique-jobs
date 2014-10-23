RSpec.configure do |config|
  config.before(:each) do |example|
    sidekiq = example.metadata[:sidekiq]
    if sidekiq
      sidekiq = :fake if sidekiq == true
      Sidekiq::Testing.send("#{sidekiq}!")
    end
    sidekiq_ver = example.metadata[:sidekiq_ver]
    if sidekiq_ver && Sidekiq::VERSION[0].to_s != sidekiq_ver.to_s
      skip("Not relevant for version #{sidekiq_ver}")
    end
  end

  config.after(:each) do |example|
    if sidekiq = example.metadata[:sidekiq]
      Sidekiq::Testing.disable!
    end
  end
end
