require 'sidekiq'

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    require 'sidekiq_unique_jobs/server/middleware'
    chain.add SidekiqUniqueJobs::Server::Middleware
  end
  config.client_middleware do |chain|
    require 'sidekiq_unique_jobs/client/middleware'
    chain.add SidekiqUniqueJobs::Client::Middleware
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    require 'sidekiq_unique_jobs/client/middleware'
    chain.add SidekiqUniqueJobs::Client::Middleware
  end
end
