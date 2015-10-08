require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilAndWhileExecuting do
  let(:item) do
    {
      'jid' => 'maaaahjid',
      'queue' => 'dupsallowed',
      'class' => 'UntilAndWhileExecuting',
      'unique' => 'until_executed',
      'args' => [1]
    }
  end
  let(:callback) { -> {} }
  subject { described_class.new(item) }
  describe '#execute' do
    before { subject.lock(:client) }
    let(:runtime_lock) { SidekiqUniqueJobs::Lock::WhileExecuting.new(item, nil) }

    it 'unlocks the unique key before yielding' do
      expect(SidekiqUniqueJobs::Lock::WhileExecuting).to receive(:new).with(item, nil).and_return(runtime_lock)
      expect(callback).to receive(:call)
      subject.execute(callback) do

        Sidekiq.redis do |c|
          expect(c.keys('uniquejobs:*').size).to eq(1)
        end

        10.times { Sidekiq::Client.push(item) }

        Sidekiq.redis do |c|
          expect(c.keys('uniquejobs:*').size).to eq(2)
        end
      end
    end
  end
end
