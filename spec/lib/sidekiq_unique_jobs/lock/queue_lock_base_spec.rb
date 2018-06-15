# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Lock::BaseLock do
  let(:lock)       { described_class.new(item, redis_pool) }
  let(:item)       { {} }
  let(:redis_pool) { nil }
  let(:locksmith)  { instance_double(SidekiqUniqueJobs::Locksmith) }

  before do
    allow(SidekiqUniqueJobs::Locksmith).to receive(:new).with(item, redis_pool).and_return(locksmith)
  end

  describe '#lock' do
    it do
      expect(locksmith).to receive(:lock).with(kind_of(Integer))
      lock.lock
    end
  end

  describe '#execute' do
    it do
      expect { lock.execute(nil) }
        .to raise_error(NotImplementedError, "#execute needs to be implemented in #{described_class}")
    end
  end

  describe '#unlock' do
    it do
      expect(locksmith).to receive(:unlock).with(no_args)
      expect(locksmith).to receive(:delete!).with(no_args)
      lock.unlock
    end
  end
end
