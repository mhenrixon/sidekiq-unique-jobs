# frozen_string_literal: true

RSpec.shared_examples "a performing worker" do |splat_arguments: true|
  let(:worker_instance) { described_class.new }

  before do
    allow(described_class).to receive(:new).and_return(worker_instance)
    allow(worker_instance).to receive(:perform).with(any_args)
  end

  it "receives the expected arguments" do
    SidekiqUniqueJobs.use_config(enabled: false) do
      Sidekiq::Testing.inline! do
        if args == no_args
          described_class.perform_async
          expect(worker_instance).to have_received(:perform).with(no_args)
        elsif splat_arguments
          described_class.perform_async(*args)
          expect(worker_instance).to have_received(:perform).with(*args)
        else
          described_class.perform_async(args)
          expect(worker_instance).to have_received(:perform).with(args)
        end
      end
    end
  end
end
