# frozen_string_literal: true

RSpec.shared_examples 'a performing worker' do |splat_arguments: true|
  let(:worker_instance) { instance_spy(described_class) }

  before do
    allow(described_class).to receive(:new).and_return(worker_instance)
  end

  it 'receives the expected arguments' do
    SidekiqUniqueJobs.use_config(enabled: false) do
      Sidekiq::Testing.inline! do
        if args == no_args
          expect(worker_instance).to receive(:perform).with(no_args)
          described_class.perform_async
        elsif splat_arguments
          expect(worker_instance).to receive(:perform).with(*args)
          described_class.perform_async(*args)
        else
          expect(worker_instance).to receive(:perform).with(args)
          described_class.perform_async(args)
        end
      end
    end
  end
end

RSpec.shared_examples 'sidekiq with options' do
  subject(:sidekiq_options) { described_class.get_sidekiq_options }

  it { is_expected.to match(a_hash_including(options)) }
end
