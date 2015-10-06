require 'spec_helper'
require 'sidekiq/worker'
require 'sidekiq-unique-jobs'
require 'sidekiq/scheduled'

RSpec.describe SidekiqUniqueJobs::Client::Middleware do
  def digest_for(item)
    SidekiqUniqueJobs::UniqueArgs.digest(item)
  end

  describe 'with real redis' do
    before do
      Sidekiq.redis = REDIS
      Sidekiq.redis(&:flushdb)
      QueueWorker.sidekiq_options unique: nil, unique_expiration: nil
    end

    describe 'when a job is already scheduled' do
      it 'rejects new scheduled jobs with the same argument' do
        MyUniqueWorker.perform_in(3600, 1)
        expect(MyUniqueWorker.perform_in(3600, 1)).to eq(nil)
      end

      it 'will run a job in real time with the same arguments' do
        WhileExecutingWorker.perform_in(3600, 1)
        expect(WhileExecutingWorker.perform_async(1)).not_to eq(nil)
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
          def do_it(arg)
            # whatever
          end
        end

        [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 20].each do |x|
          ShitClass.delay_for(x, unique_lock: :while_executing).do_it(1)
        end

        Sidekiq.redis do |c|
          count = c.zcount('schedule', -1, Time.now.to_f + 2 * 60)
          expect(count).to eq(20)
        end
      end
    end

    it 'does not push duplicate messages when configured for unique only' do
      item = { 'class' => MyUniqueWorker, 'queue' => 'customqueue', 'args' => [1, 2] }
      10.times { Sidekiq::Client.push(item) }
      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq(1)
      end
    end

    it 'does push duplicate messages to different queues' do
      Sidekiq::Client.push('class' => MyUniqueWorker, 'queue' => 'customqueue', 'args' => [1, 2])
      Sidekiq::Client.push('class' => MyUniqueWorker, 'queue' => 'customqueue2', 'args' => [1, 2])
      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq 1
        expect(c.llen('queue:customqueue2')).to eq 1
      end
    end

    it 'does not queue duplicates when when calling delay' do
      10.times { PlainClass.delay(unique_lock: :until_executed, unique: true, queue: 'customqueue').run(1) }
      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq(1)
      end
    end

    it 'does not schedule duplicates when calling perform_in' do
      10.times { MyUniqueWorker.perform_in(60, [1, 2]) }
      Sidekiq.redis do |c|
        expect(c.zcount('schedule', -1, Time.now.to_f + 2 * 60))
          .to eq(1)
      end
    end

    it 'enqueues previously scheduled job' do
      jid = WhileExecutingWorker.perform_in(60 * 60, 1, 2)
      item = { 'class' => WhileExecutingWorker, 'queue' => 'customqueue', 'args' => [1, 2], 'jid' => jid }

      # time passes and the job is pulled off the schedule:
      Sidekiq::Client.push(item)

      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq 1
      end
    end

    it 'sets an expiration when provided by sidekiq options' do
      item = { 'class' => ExpiringWorker, 'queue' => 'customqueue', 'args' => [1, 2] }
      Sidekiq::Client.push(item)

      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq(1)
        expect(c.ttl(digest_for(item)))
          .to eq(ExpiringWorker.get_sidekiq_options['unique_expiration'])
      end
    end

    it 'does push duplicate messages when not configured for unique only' do
      10.times { Sidekiq::Client.push('class' => QueueWorker, 'queue' => 'customqueue', 'args' => [1, 2]) }

      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq(10)
      end
    end

    describe 'when unique_args is defined' do
      before(:all) { SidekiqUniqueJobs.config.unique_args_enabled = true }
      after(:all)  { SidekiqUniqueJobs.config.unique_args_enabled = false }

      it 'does not push duplicate messages based on args filter method' do
        expect(QueueWorkerWithFilterMethod).to respond_to(:args_filter)
        expect(QueueWorkerWithFilterMethod.get_sidekiq_options['unique_args']).to eq :args_filter

        (0..10).each do |i|
          Sidekiq::Client.push(
            'class' => QueueWorkerWithFilterMethod,
            'queue' => 'customqueue',
            'args' => [1, i]
          )
        end

        Sidekiq.redis do |c|
          expect(c.llen('queue:customqueue')).to eq(1)
        end
      end

      it 'does not push duplicate messages based on args filter proc' do
        expect(QueueWorkerWithFilterProc.get_sidekiq_options['unique_args']).to be_a(Proc)

        100.times do
          Sidekiq::Client.push(
            'class' => QueueWorkerWithFilterProc,
            'queue' => 'customqueue',
            'args' => [1, { random: rand, name: 'foobar' }]
          )
        end

        Sidekiq.redis do |c|
          expect(c.llen('queue:customqueue')).to eq(1)
        end
      end

      describe 'when unique_on_all_queues is set' do
        it 'does not push duplicate messages on different queues' do
          item = { 'class' => UniqueOnAllQueuesWorker, 'args' => [1, 2] }
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
        (Time.at(Time.now.to_i + 15 * 60) - Time.now.utc) + SidekiqUniqueJobs.config.default_expiration
      jid = MyUniqueWorker.perform_in(expected_expires_at, 'mike')
      item = { 'class' => MyUniqueWorker,
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
      UniqueWorker.sidekiq_options log_duplicate_payload: true
      2.times { Sidekiq::Client.push('class' => UniqueWorker, 'queue' => 'customqueue', 'args' => [1, 2]) }
      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq 1
      end
      UniqueWorker.sidekiq_options log_duplicate_payload: true
    end

    it 'does not log duplicate payload when config turned off' do
      expect(Sidekiq.logger).to_not receive(:warn).with(/^payload is not unique/)

      UniqueWorker.sidekiq_options log_duplicate_payload: false

      2.times { Sidekiq::Client.push('class' => UniqueWorker, 'queue' => 'customqueue', 'args' => [1, 2]) }
      Sidekiq.redis do |c|
        expect(c.llen('queue:customqueue')).to eq 1
      end
      UniqueWorker.sidekiq_options log_duplicate_payload: true
    end
  end
end
