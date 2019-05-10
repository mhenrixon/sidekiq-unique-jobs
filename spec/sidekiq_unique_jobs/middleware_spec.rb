# frozen_string_literal: true

require "spec_helper"
RSpec.describe SidekiqUniqueJobs::Middleware do
  let(:client_config)     { class_double(Sidekiq) }
  let(:server_config)     { class_double(Sidekiq) }
  let(:client_middleware) { instance_spy(Sidekiq::Middleware::Chain) }
  let(:server_middleware) { instance_spy(Sidekiq::Middleware::Chain) }

  before do
    allow(Sidekiq).to receive(:configure_client).and_yield(client_config)
    allow(Sidekiq).to receive(:configure_server).and_yield(server_config)

    allow(client_config).to receive(:client_middleware).and_yield(client_middleware)

    allow(server_config).to receive(:client_middleware).and_yield(client_middleware)
    allow(server_config).to receive(:server_middleware).and_yield(server_middleware)
  end

  shared_examples "configures client middleware" do
    it "adds client middleware when required" do
      expect(client_config).to have_received(:client_middleware)
      expect(client_middleware).to have_received(:add).with(SidekiqUniqueJobs::Middleware::Client).at_least(:once)
    end
  end

  shared_examples "configures server middleware" do
    it "adds client and server middleware when required" do
      expect(server_config).to have_received(:client_middleware).at_least(:once)
      expect(client_middleware).to have_received(:add).with(SidekiqUniqueJobs::Middleware::Client).at_least(:once)

      expect(server_config).to have_received(:server_middleware)
      expect(server_middleware).to have_received(:add).with(SidekiqUniqueJobs::Middleware::Server)
    end
  end

  describe ".configure" do
    before { described_class.configure }

    it_behaves_like "configures client middleware"
    it_behaves_like "configures server middleware"
  end

  describe ".configure_server" do
    before { described_class.configure_server }

    it_behaves_like "configures server middleware"
  end

  describe ".configure_client" do
    before { described_class.configure_client }

    it_behaves_like "configures client middleware"
  end
end
