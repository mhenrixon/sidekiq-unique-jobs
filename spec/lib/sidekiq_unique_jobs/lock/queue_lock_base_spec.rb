# frozen_string_literal: true

RSpec.describe SidekiqUniqueJobs::Lock::QueueLockBase do
  let(:lock)       { described_class.new(item, redis_pool) }
  let(:item)       { {} }
  let(:redis_pool) { nil }

  describe '#lock' do
    it do
      expect { lock.lock(nil) }
        .to raise_error(NotImplementedError, "#lock needs to be implemented in #{described_class}")
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
      expect { lock.unlock(nil) }
        .to raise_error(NotImplementedError, "#unlock needs to be implemented in #{described_class}")
    end
  end
end
