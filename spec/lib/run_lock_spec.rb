require 'spec_helper'
require 'sidekiq_unique_jobs/run_lock'

RSpec.describe SidekiqUniqueJobs::RunLock do
  it 'allows only one mutex object to have the lock at a time' do
    mutexes = (1..10).map do
      SidekiqUniqueJobs.connection do |conn|
        SidekiqUniqueJobs::RunLock.new('test_mutex_key', conn)
      end
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
    m = SidekiqUniqueJobs.connection do |conn|
      SidekiqUniqueJobs::RunLock.new('test_mutex_key', conn)
    end

    SidekiqUniqueJobs.connection do |conn|
      conn.setnx 'test_mutex_key', Time.now.to_i - 1
    end

    start = Time.now.to_i
    m.synchronize do
      'nop'
    end

    # no longer than a second
    expect(Time.now.to_i).to be <= start + 1
  end

  it 'maintains mutex semantics' do
    m = SidekiqUniqueJobs.connection do |conn|
      SidekiqUniqueJobs::RunLock.new('test_mutex_key', conn)
    end

    expect do
      m.synchronize do
        m.synchronize {}
      end
    end.to raise_error(ThreadError)
  end
end
