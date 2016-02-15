require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::TimeoutCalculator do
  shared_context 'undefined worker class' do
    subject do
      Class.new do
        include SidekiqUniqueJobs::TimeoutCalculator
        def initialize(item)
          @item = item
        end
      end.new('class' => 'test')
    end
  end

  shared_context 'generic unscheduled job' do
    subject do
      Class.new do
        include SidekiqUniqueJobs::TimeoutCalculator
        def initialize(item)
          @item = item
        end
      end.new('class' => 'MyUniqueJob')
    end
  end

  describe 'public api' do
    it_behaves_like 'generic unscheduled job' do
      it { is_expected.to respond_to(:time_until_scheduled) }
      it { is_expected.to respond_to(:worker_class_queue_lock_expiration) }
      it { is_expected.to respond_to(:worker_class_run_lock_expiration) }
      it { is_expected.to respond_to(:worker_class) }
    end
  end

  describe '#time_until_scheduled' do
    it_behaves_like 'generic unscheduled job' do
      its(:time_until_scheduled) { is_expected.to eq(0) }
    end

    subject do
      Class.new do
        include SidekiqUniqueJobs::TimeoutCalculator
        def initialize(item)
          @item = item
        end
      end.new('class' => 'MyUniqueJob', 'at' => schedule_time)
    end
    let(:schedule_time) { Time.now.utc.to_i + 24 * 60 * 60 }
    let(:now_in_utc) { Time.now.utc.to_i }

    its(:time_until_scheduled) do
      Timecop.travel(Time.at(now_in_utc)) do
        is_expected.to be_within(1).of(schedule_time - now_in_utc)
      end
    end
  end

  describe '#worker_class_queue_lock_expiration' do
    it_behaves_like 'undefined worker class' do
      its (:worker_class_queue_lock_expiration) { is_expected.to eq(nil) }
    end

    it_behaves_like 'generic unscheduled job' do
      its (:worker_class_queue_lock_expiration) { is_expected.to eq(7_200) }
    end
  end

  describe '#worker_class_run_lock_expiration' do
    it_behaves_like 'undefined worker class' do
      its (:worker_class_queue_lock_expiration) { is_expected.to eq(nil) }
    end

    subject do
      Class.new do
        include SidekiqUniqueJobs::TimeoutCalculator
        def initialize(item)
          @item = item
        end
      end.new('class' => 'LongRunningJob')
    end
    its (:worker_class_run_lock_expiration) { is_expected.to eq(7_200) }
  end

  describe '#worker_class' do
    it_behaves_like 'undefined worker class' do
      its(:worker_class) { is_expected.to eq('test') }
    end

    subject do
      Class.new do
        include SidekiqUniqueJobs::TimeoutCalculator
        def initialize(item)
          @item = item
        end
      end.new('class' => 'MyJob')
    end
    its(:worker_class) { is_expected.to eq(MyJob) }
  end
end
