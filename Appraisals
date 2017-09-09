# frozen_string_literal: true

appraise 'sidekiq-develop' do
  gem 'mock_redis'
  gem 'sidekiq', github: 'mperham/sidekiq'
end

appraise 'sidekiq-4.0' do
  gem 'mock_redis'
  gem 'sidekiq', '~> 4.0.0'
end

appraise 'sidekiq-4.1' do
  gem 'mock_redis'
  gem 'sidekiq', '~> 4.1.0'
end

appraise 'sidekiq-4.2' do
  gem 'mock_redis'
  gem 'sidekiq', '~> 4.2.0'
end

appraise 'sidekiq-5.0' do
  gem 'mock_redis'
  gem 'sidekiq', '>= 5.0.0.beta', '< 6'
end
