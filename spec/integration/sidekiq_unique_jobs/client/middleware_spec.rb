# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/worker'
require 'sidekiq-unique-jobs'
require 'rspec/wait'

RSpec.describe SidekiqUniqueJobs::Client::Middleware, redis: :redis, redis_db: 1 do
  describe 'when a job is already scheduled' do
    it 'processes jobs properly' do
      jid = NotifyWorker.perform_in(1, 183, 'xxxx')
      expect(jid).not_to eq(nil)
      Sidekiq.redis do |conn|
        expect(conn.zcard('schedule')).to eq(1)
        expected = %w[
          uniquejobs:6e47d668ad22db2a3ba0afd331514ce2:EXISTS
          uniquejobs:6e47d668ad22db2a3ba0afd331514ce2:VERSION
        ]

        expect(conn.keys).to include(*expected)
      end
      Sidekiq::Scheduled::Enq.new.enqueue_jobs

      Sidekiq::Simulator.process_queue(:notify_worker) do
        expect(0).to eventually be_enqueued_in('notify_worker')
      end
    end

    it 'rejects nested subsequent jobs with the same arguments' do
      expect(SimpleWorker.perform_async(1)).not_to eq(nil)
      expect(SimpleWorker.perform_async(1)).to eq(nil)
      expect(SpawnSimpleWorker.perform_async(1)).not_to eq(nil)

      expect(1).to be_enqueued_in('default')
      expect(1).to be_enqueued_in('not_default')

      Sidekiq::Simulator.process_queue(:not_default) do
        expect(0).to eventually be_enqueued_in('not_default')
      end

      Sidekiq::Simulator.process_queue(:default) do
        expect(0).to eventually be_enqueued_in('default')
      end
    end

    it 'schedules new jobs when arguments differ' do
      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20].each do |x|
        MainJob.perform_in(x, x)
      end

      expect(20).to be_scheduled_at(Time.now.to_f + 2 * 60)
    end

    it 'schedules allows jobs to be scheduled ' do
      class ShitClass
        def self.do_it(_one)
          # whatever
        end
      end

      [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20].each do |x|
        ShitClass.delay_for(x, unique: :while_executing).do_it(1)
      end

      expect(20).to be_scheduled_at(Time.now.to_f + 2 * 60)
    end
  end

  it 'does not push duplicate messages when unique_args are filtered with a proc' do
    10.times { MyUniqueJobWithFilterProc.perform_async(1) }
    expect(1).to be_enqueued_in('customqueue')

    Sidekiq.redis(&:flushdb)
    expect(0).to be_enqueued_in('customqueue')

    10.times do
      Sidekiq::Client.push(
        'class' => MyUniqueJobWithFilterProc,
        'queue' => 'customqueue',
        'args' => [1, type: 'value', some: 'not used'],
      )
    end

    expect(1).to be_enqueued_in('customqueue')
  end

  it 'does not push duplicate messages when unique_args are filtered with a method' do
    10.times { MyUniqueJobWithFilterMethod.perform_async(1) }

    expect(1).to be_enqueued_in('customqueue')
    Sidekiq.redis(&:flushdb)
    expect(0).to be_enqueued_in('customqueue')

    10.times do
      Sidekiq::Client.push(
        'class' => MyUniqueJobWithFilterMethod,
        'queue' => 'customqueue',
        'args' => [1, type: 'value', some: 'not used'],
      )
    end

    expect(1).to be_enqueued_in('customqueue')
  end

  it 'does not queue duplicates when when calling delay' do
    10.times { PlainClass.delay(unique: :until_executed, queue: 'customqueue').run(1) }

    expect(1).to be_enqueued_in('customqueue')
  end

  context 'when class is not unique' do
    it 'pushes duplicate messages' do
      10.times do
        Sidekiq::Client.push('class' => CustomQueueJob, 'queue' => 'customqueue', 'args' => [1, 2])
      end

      expect(10).to be_enqueued_in('customqueue')
    end
  end

  describe 'when unique_args is defined' do
    context 'when filter method is defined' do
      it 'pushes no duplicate messages' do
        expect(CustomQueueJobWithFilterMethod).to respond_to(:args_filter)
        expect(CustomQueueJobWithFilterMethod.get_sidekiq_options['unique_args']).to eq :args_filter

        (0..10).each do |i|
          Sidekiq::Client.push(
            'class' => CustomQueueJobWithFilterMethod,
            'queue' => 'customqueue',
            'args' => [1, i],
          )
        end

        expect(1).to be_enqueued_in('customqueue')
      end
    end

    context 'when filter proc is defined' do
      let(:args) { [1, { random: rand, name: 'foobar' }] }

      it 'pushes no duplicate messages' do
        100.times { CustomQueueJobWithFilterProc.perform_async(args) }

        expect(1).to be_enqueued_in('customqueue')
      end
    end

    context 'when unique_on_all_queues is set' do
      it 'pushes no duplicate messages on other queues' do
        item = { 'class' => UniqueOnAllQueuesJob, 'args' => [1, 2] }
        Sidekiq::Client.push(item.merge('queue' => 'customqueue'))
        Sidekiq::Client.push(item.merge('queue' => 'customqueue2'))

        expect(1).to be_enqueued_in('customqueue')
        expect(0).to be_enqueued_in('customqueue2')
      end
    end

    context 'when unique_across_workers is set' do
      it 'does not push duplicate messages for other workers' do
        item_one = {
          'queue' => 'customqueue1',
          'class' => UniqueAcrossWorkersJob,
          'unique_across_workers' => true,
          'args' => [1, 2],
        }

        item_two = {
          'queue' => 'customqueue1',
          'class' => MyUniqueJob,
          'unique_across_workers' => true,
          'args' => [1, 2],
        }

        Sidekiq::Client.push(item_one)
        Sidekiq::Client.push(item_two)

        expect(1).to be_enqueued_in('customqueue1')
      end
    end
  end

  it 'expires the digest when a scheduled job is scheduled at' do
    expected_expires_at = Time.now.to_i + 15 * 60 - Time.now.utc.to_i

    MyUniqueJob.perform_in(expected_expires_at, 'mika', 'hel')

    Sidekiq.redis do |conn|
      conn.keys('uniquejobs:*').each do |key|
        next if key.end_with?(':GRABBED')
        expect(conn.ttl(key)).to be_within(10).of(8_099)
      end
    end
  end

  it 'logs duplicate payload when config turned on' do
    expect(Sidekiq.logger).to receive(:warn).with(/^payload is not unique/)

    UntilExecutedJob.use_config(log_duplicate_payload: true) do
      2.times do
        Sidekiq::Client.push('class' => UntilExecutedJob, 'queue' => 'customqueue', 'args' => [1, 2])
      end

      expect(1).to be_enqueued_in('customqueue')
    end
  end

  it 'does not log duplicate payload when config turned off' do
    expect(SidekiqUniqueJobs.logger).not_to receive(:warn).with(/^payload is not unique/)

    UntilExecutedJob.use_config(log_duplicate_payload: false) do
      2.times do
        Sidekiq::Client.push('class' => UntilExecutedJob, 'queue' => 'customqueue', 'args' => [1, 2])
      end

      expect(1).to be_enqueued_in('customqueue')
    end
  end
end
