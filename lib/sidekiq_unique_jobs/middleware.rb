require 'sidekiq/middleware/chain'
require 'sidekiq/processor'

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    require 'sidekiq_unique_jobs/middleware/server/unique_jobs'
    chain.add SidekiqUniqueJobs::Middleware::Server::UniqueJobs
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    require 'sidekiq_unique_jobs/middleware/client/unique_jobs'
    chain.add SidekiqUniqueJobs::Middleware::Client::UniqueJobs
  end
end