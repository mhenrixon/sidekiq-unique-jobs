RSpec.configure do |config|
  config.before(:each) do |example|
    if (sidekiq = example.metadata[:sidekiq])
      sidekiq = :fake if sidekiq == true
      Sidekiq::Testing.send("#{sidekiq}!")
    end
  end

  config.after(:each) do |example|
    Sidekiq::Testing.disable! unless example.metadata[:sidekiq].nil?
  end
end
