require 'sidekiq'

Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    require 'sidekiq-unique-jobs/middleware/server/unique_jobs'
    chain.add SidekiqUniqueJobs::Middleware::Server::UniqueJobs
  end
end

Sidekiq.configure_client do |config|
  config.client_middleware do |chain|
    require 'sidekiq-unique-jobs/middleware/client/unique_jobs'
    chain.add SidekiqUniqueJobs::Middleware::Client::UniqueJobs
  end
end
