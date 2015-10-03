require 'spec_helper'
RSpec.describe SidekiqUniqueJobs do
  describe '.configure_middleware' do
    it 'configures both client and server middleware' do
      expect(described_class).to receive(:configure_server_middleware)
      expect(described_class).to receive(:configure_client_middleware)

      described_class.configure_middleware
    end
  end

  describe '.configure_server_middleware' do
    let(:server_config) { class_double(Sidekiq) }
    let(:server_middleware) { double(Sidekiq::Middleware::Chain) }

    it 'adds server middleware when required' do
      expect(Sidekiq).to receive(:configure_server).and_yield(server_config)
      expect(server_config).to receive(:server_middleware).and_yield(server_middleware)
      expect(server_middleware).to receive(:add).with(SidekiqUniqueJobs::Server::Middleware)
      described_class.configure_server_middleware
    end
  end

  describe '.configure_client_middleware' do
    let(:client_config) { class_double(Sidekiq) }
    let(:client_middleware) { double(Sidekiq::Middleware::Chain) }

    it 'adds client middleware when required' do
      expect(Sidekiq).to receive(:configure_client).and_yield(client_config)
      expect(client_config).to receive(:client_middleware).and_yield(client_middleware)
      expect(client_middleware).to receive(:add).with(SidekiqUniqueJobs::Client::Middleware)

      described_class.configure_client_middleware
    end
  end
end
