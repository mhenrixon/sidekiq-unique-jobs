RSpec.configure do |config|
  config.before(:each) do |example|
    sidekiq = example.metadata[:sidekiq]
    if sidekiq
      sidekiq = :fake if sidekiq == true
      Sidekiq::Testing.send("#{sidekiq}!")
    end
  end

  config.after(:each) do |example|
    if sidekiq = example.metadata[:sidekiq]
      Sidekiq::Testing.disable!
    end
  end
end