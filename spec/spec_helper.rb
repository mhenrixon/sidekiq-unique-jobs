$TESTING = true

begin
  require 'pry'
rescue LoadError
end

require 'rspec/autorun'
require 'rspec'

require 'celluloid/test'
require 'sidekiq'
require 'sidekiq/util'
require 'sidekiq-unique-jobs'
Sidekiq.logger.level = Logger::ERROR

require 'sidekiq/testing'
require 'rspec-sidekiq'

Sidekiq::Testing.disable!

require 'sidekiq/redis_connection'
redis_url = ENV['REDIS_URL'] || 'redis://localhost/15'
REDIS = Sidekiq::RedisConnection.create(:url => redis_url, :namespace => 'testy')

Dir[File.join(File.dirname(__FILE__), 'support', '**', '*.rb')].each { |f| require f }
RSpec.configure do |config|
  config.treat_symbols_as_metadata_keys_with_true_values = true
end