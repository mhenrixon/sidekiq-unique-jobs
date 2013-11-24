RSpec.configure do |config|
  config.before(:each) do # |example| TODO: Add this for RSpec 3
    sidekiq = example.metadata[:sidekiq]
    if sidekiq
      sidekiq = :fake if sidekiq == true
      Sidekiq::Testing.send("#{sidekiq}!")
    end
  end

  config.after(:each) do # |example| TODO: Add this for RSpec 3
    if sidekiq = example.metadata[:sidekiq]
      Sidekiq::Testing.disable!
    end
  end
end