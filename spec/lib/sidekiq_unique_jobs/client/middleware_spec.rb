# frozen_string_literal: true

require 'spec_helper'
require 'sidekiq/worker'
require 'sidekiq-unique-jobs'
require 'rspec/wait'

RSpec.describe SidekiqUniqueJobs::Client::Middleware do
  def digest_for(item)
    SidekiqUniqueJobs::UniqueArgs.digest(item)
  end

  describe 'with real redis' do
    describe 'when a job is already scheduled' do
      it 'processes jobs properly' do
        Sidekiq::Testing.disable! do
          jid = NotifyWorker.perform_in(1, 183, 'xxxx')
          expect(jid).not_to eq(nil)
          Sidekiq.redis do |c|
            expect(c.zcard('schedule')).to eq(1)
            expected = %w[schedule uniquejobs:6e47d668ad22db2a3ba0afd331514ce2 uniquejobs]
            expect(c.keys).to match_array(expected)
          end
          sleep 1
          Sidekiq::Scheduled::Enq.new.enqueue_jobs

          Sidekiq.redis do |c|
            wait(10).for { c.llen('queue:notify_worker') }.to eq(1)
          end

          Sidekiq::Simulator.process_queue(:notify_worker) do
            Sidekiq.redis do |c|
              wait(10).for { c.llen('queue:notify_worker') }.to eq(0)
            end
          end
        end
      end

      it 'rejects nested subsequent jobs with the same arguments' do
        Sidekiq::Testing.disable! do
          expect(SimpleWorker.perform_async(1)).not_to eq(nil)
          expect(SimpleWorker.perform_async(1)).to eq(nil)
          expect(SpawnSimpleWorker.perform_async(1)).not_to eq(nil)

          Sidekiq.redis do |c|
            expect(c.llen('queue:default')).to eq(1)
            expect(c.llen('queue:not_default')).to eq(1)
          end

          Sidekiq::Simulator.process_queue(:not_default) do
            Sidekiq.redis do |c|
              expect(c.llen('queue:default')).to eq(1)
              wait(10).for { c.llen('queue:not_default') }.to eq(0)
              expect(c.llen('queue:default')).to eq(1)
            end
          end

          Sidekiq.redis do |c|
            expect(c.llen('queue:default')).to eq(1)
          end

          Sidekiq::Simulator.process_queue(:default) do
            Sidekiq.redis do |c|
              expect(c.llen('queue:not_default')).to eq(0)
              wait(10).for { c.llen('queue:default') }.to eq(0)
            end
          end
        end
      end

      it 'rejects new scheduled jobs with the same argument' do
        MyUniqueJob.perform_in(3600, 1)
        expect(MyUniqueJob.perform_in(3600, 1)).to eq(nil)
      end

      it 'will run a job in real time with the same arguments' do
        WhileExecutingJob.perform_in(3600, 1)
        expect(WhileExecutingJob.perform_async(1)).not_to eq(nil)
      end

      it 'schedules new jobs when arguments differ' do
        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20].each do |x|
          MainJob.perform_in(x, x)
        end

        Sidekiq.redis do |c|
          count = c.zcount('schedule', -1, Time.now.to_f + 2 * 60)
          expect(count).to eq(20)
        end
      end

      it 'schedules allows jobs to be scheduled ' do
        class ShitClass
          def do_it(_arg)
            # whatever
          end
        end

        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20].each do |x|
          ShitClass.delay_for(x, unique: :while_executing).do_it(1)
        end

        Sidekiq.redis do |c|
          count = c.zcount('schedule', -1, Time.now.to_f + 2 * 60)
          expect(count).to eq(20)
        end
      end
    end

    it 'does not push duplicate messages when configured for unique only' do
      10.times { MyUniqueJob.perform_async(1, 2) }
      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq(1)
      end
    end

    it 'does not push duplicate messages when unique_args are filtered with a proc' do
      10.times { MyUniqueJobWithFilterProc.perform_async(1) }
      Sidekiq.redis { |c| expect(c.llen('queue:customqueue')).to eq(1) }

      Sidekiq.redis(&:flushdb)
      Sidekiq.redis { |c| expect(c.llen('queue:customqueue')).to eq(0) }

      10.times do
        Sidekiq::Client.push(
          'class' => MyUniqueJobWithFilterProc,
          'queue' => 'customqueue',
          'args' => [1, type: 'value', some: 'not used'],
        )
      end
      Sidekiq.redis { |c| expect(c.llen('queue:customqueue')).to eq(1) }
    end

    it 'does not push duplicate messages when unique_args are filtered with a method' do
      10.times { MyUniqueJobWithFilterMethod.perform_async(1) }
      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq(1)
      end
      Sidekiq.redis(&:flushdb)
      Sidekiq.redis { |c| expect(c.llen('queue:customqueue')).to eq(0) }
      10.times do
        Sidekiq::Client.push(
          'class' => MyUniqueJobWithFilterMethod,
          'queue' => 'customqueue',
          'args' => [1, type: 'value', some: 'not used'],
        )
      end
      Sidekiq.redis { |c| expect(c.llen('queue:customqueue')).to eq(1) }
    end

    it 'does push duplicate messages to different queues' do
      Sidekiq::Client.push('class' => MyUniqueJob, 'queue' => 'customqueue', 'args' => [1, 2])
      Sidekiq::Client.push('class' => MyUniqueJob, 'queue' => 'customqueue2', 'args' => [1, 2])
      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq 1
        expect(c.llen('queue:customqueue2')).to eq 1
      end
    end

    it 'does not queue duplicates when when calling delay' do
      10.times { PlainClass.delay(unique: :until_executed, queue: 'customqueue').run(1) }
      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq(1)
      end
    end

    it 'does not schedule duplicates when calling perform_in' do
      10.times { MyUniqueJob.perform_in(60, [1, 2]) }
      Sidekiq.redis do |c|
        expect(c.zcount('schedule', -1, Time.now.to_f + 2 * 60))
          .to eq(1)
      end
    end

    it 'enqueues previously scheduled job' do
      jid = WhileExecutingJob.perform_in(60 * 60, 1, 2)
      item = { 'class' => WhileExecutingJob, 'queue' => 'customqueue', 'args' => [1, 2], 'jid' => jid }

      # time passes and the job is pulled off the schedule:
      Sidekiq::Client.push(item)

      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq 1
      end
    end

    it 'sets an expiration when provided by sidekiq options' do
      item = { 'class' => ExpiringJob, 'queue' => 'customqueue', 'args' => [1, 2] }
      Sidekiq::Client.push(item)

      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq(1)
        expect(c.ttl(digest_for(item)))
          .to eq(ExpiringJob.get_sidekiq_options['unique_expiration'])
      end
    end

    it 'does push duplicate messages when not configured for unique only' do
      10.times do
        Sidekiq::Client.push('class' => CustomQueueJob, 'queue' => 'customqueue', 'args' => [1, 2])
      end

      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq(10)
      end
    end

    describe 'when unique_args is defined' do
      it 'does not push duplicate messages based on args filter method' do
        expect(CustomQueueJobWithFilterMethod).to respond_to(:args_filter)
        expect(CustomQueueJobWithFilterMethod.get_sidekiq_options['unique_args']).to eq :args_filter

        (0..10).each do |i|
          Sidekiq::Client.push(
            'class' => CustomQueueJobWithFilterMethod,
            'queue' => 'customqueue',
            'args' => [1, i],
          )
        end

        Sidekiq.redis do |c|
          expect(c.llen('queue:customqueue')).to eq(1)
        end
      end

      it 'does not push duplicate messages based on args filter proc' do
        expect(CustomQueueJobWithFilterProc.get_sidekiq_options['unique_args']).to be_a(Proc)

        100.times do
          Sidekiq::Client.push(
            'class' => CustomQueueJobWithFilterProc,
            'queue' => 'customqueue',
            'args' => [1, { random: rand, name: 'foobar' }],
          )
        end

        Sidekiq.redis do |c|
          expect(c.llen('queue:customqueue')).to eq(1)
        end
      end

      describe 'when unique_on_all_queues is set' do
        it 'does not push duplicate messages on different queues' do
          item = { 'class' => UniqueOnAllQueuesJob, 'args' => [1, 2] }
          Sidekiq::Client.push(item.merge('queue' => 'customqueue'))
          Sidekiq::Client.push(item.merge('queue' => 'customqueue2'))
          Sidekiq.redis do |c|
            expect(c.llen('queue:customqueue')).to eq(1)
            expect(c.llen('queue:customqueue2')).to eq(0)
          end
        end
      end
    end

    # TODO: If anyone know of a better way to check that the expiration for scheduled
    # jobs are set around the same time as the scheduled job itself feel free to improve.
    it 'expires the digest when a scheduled job is scheduled at' do
      expected_expires_at =
        (Time.at(Time.now.to_i + 15 * 60) - Time.now.utc) +
        SidekiqUniqueJobs.config.default_queue_lock_expiration
      jid = MyUniqueJob.perform_in(expected_expires_at, 'mike')
      item = { 'class' => MyUniqueJob,
               'queue' => 'customqueue',
               'args' => ['mike'],
               'at' => expected_expires_at }
      digest = digest_for(item.merge('jid' => jid))
      Sidekiq.redis do |c|
        expect(c.ttl(digest)).to eq(9_899)
      end
    end

    it 'logs duplicate payload when config turned on' do
      expect(Sidekiq.logger).to receive(:warn).with(/^payload is not unique/)
      UntilExecutedJob.sidekiq_options log_duplicate_payload: true
      2.times do
        Sidekiq::Client.push('class' => UntilExecutedJob, 'queue' => 'customqueue', 'args' => [1, 2])
      end
      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq 1
      end
      UntilExecutedJob.sidekiq_options log_duplicate_payload: true
    end

    it 'does not log duplicate payload when config turned off' do
      expect(SidekiqUniqueJobs.logger).to_not receive(:warn).with(/^payload is not unique/)

      UntilExecutedJob.sidekiq_options log_duplicate_payload: false

      2.times do
        Sidekiq::Client.push('class' => UntilExecutedJob, 'queue' => 'customqueue', 'args' => [1, 2])
      end
      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq 1
      end
      UntilExecutedJob.sidekiq_options log_duplicate_payload: true
    end
  end

  describe '#call' do
    let(:worker_class) { SimpleWorker }
    let(:item) do
      { 'class' => SimpleWorker,
        'queue' => 'default',
        'args'  => [1] }
    end
    let(:queue) { 'default' }
    context 'when ordinary_or_locked?' do
      before do
        allow(subject).to receive(:disabled_or_successfully_locked?).and_return(false)
      end

      it 'returns nil' do
        expect(subject.call(worker_class, item, queue))
          .to eq(nil)
      end
    end
  end
end
