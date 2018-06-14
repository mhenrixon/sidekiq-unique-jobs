# frozen_string_literal: true

RSpec.shared_examples 'a performing worker' do |args:, splat: true|
  let(:worker_instance) { described_class.new }

  it do
    Sidekiq::Testing.inline! do
      allow(described_class).to receive(:new).and_return(worker_instance)
      if args.nil?
        expect(worker_instance).to receive(:perform).with(no_args)
        described_class.perform_async
      elsif splat
        expect(worker_instance).to receive(:perform).with(*args)
        described_class.perform_async(*args)
      else
        expect(worker_instance).to receive(:perform).with(args)
        described_class.perform_async(args)
      end
    end
  end
end

RSpec.shared_examples 'sidekiq with options' do |options:|
  it { expect(described_class.get_sidekiq_options).to match(a_hash_including(options)) }
end
