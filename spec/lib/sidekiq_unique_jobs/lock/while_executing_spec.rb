require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::WhileExecuting do
  let(:item) do
    {
      'jid' => 'maaaahjid',
      'queue' => 'dupsallowed',
      'class' => 'UntilAndWhileExecuting',
      'unique' => 'until_executed',
      'unique_digest' => 'test_mutex_key',
      'args' => [1]
    }
  end

  it 'allows only one mutex object to have the lock at a time' do
    mutexes = (1..10).map do
      described_class.new(item)
    end

    x = 0
    mutexes.map do |m|
      Thread.new do
        m.synchronize do
          y = x
          sleep 0.001
          x = y + 1
        end
      end
    end.map(&:join)

    expect(x).to eq(10)
  end

  it 'handles auto cleanup correctly' do
    m = described_class.new(item)

    SidekiqUniqueJobs.connection do |conn|
      conn.set 'test_mutex_key:run', Time.now.to_i - 1, nx: true
    end

    start = Time.now.to_i
    m.synchronize do
      'nop'
    end

    # no longer than a second
    expect(Time.now.to_i).to be <= start + 1
  end

  it 'maintains mutex semantics' do
    m = described_class.new(item)

    expect do
      m.synchronize do
        m.synchronize {}
      end
    end.to raise_error(ThreadError)
  end
end
