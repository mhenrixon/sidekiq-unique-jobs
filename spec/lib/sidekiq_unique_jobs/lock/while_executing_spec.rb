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

  it 'expires the lock on the mutex object after run_lock_expiration if specified' do
    mutexes = (1..10).map do
      described_class.new(item)
    end

    worker = SidekiqUniqueJobs.worker_class_constantize(item[SidekiqUniqueJobs::CLASS_KEY])
    allow(worker).to receive(:get_sidekiq_options)
                 .and_return({"retry"=>true,
                              "queue"=>:dupsallowed,
                              "run_lock_expiration" => 0,
                              "unique"=>:until_and_while_executing})

    start_times = []
    sleep_time = 0.1
    mutexes.each_with_index.map do |m, i|
      Thread.new do
        m.synchronize do
          start_times[i] = Time.now
          sleep sleep_time
        end
      end
    end.map(&:join)

    expect(start_times.size).to be 10
    expect(start_times.sort.last - start_times.sort.first).to be < sleep_time * 10
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
