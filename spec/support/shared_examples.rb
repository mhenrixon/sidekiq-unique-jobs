# frozen_string_literal: true

RSpec.shared_examples 'a performing worker' do |args:, splat: true|
  let(:worker_instance) { described_class.new }

  it do
    allow(described_class).to receive(:new).and_return(worker_instance)
    if args.nil?
      expect(worker_instance).to receive(:perform).with(no_args)
      described_class.new.perform
    elsif splat
      expect(worker_instance).to receive(:perform).with(*args)
      described_class.new.perform(*args)
    else
      expect(worker_instance).to receive(:perform).with(args)
      described_class.new.perform(args)
    end
  end
end

RSpec.shared_examples 'sidekiq with options' do |options:|
  it { expect(described_class.get_sidekiq_options).to match(a_hash_including(options)) }
end
