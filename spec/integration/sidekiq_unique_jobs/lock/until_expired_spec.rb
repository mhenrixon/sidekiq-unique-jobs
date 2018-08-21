# frozen_string_literal: true

require 'spec_helper'

RSpec.describe SidekiqUniqueJobs::Lock::UntilExpired, redis: :redis do
  include SidekiqHelpers

  let(:process_one) { described_class.new(item_one, callback) }
  let(:process_two) { described_class.new(item_two, callback) }

  let(:jid_one)      { 'jid one' }
  let(:jid_two)      { 'jid two' }
  let(:worker_class) { UntilExpiredJob }
  let(:unique)       { :until_expired }
  let(:queue)        { :rejecting }
  let(:args)         { %w[array of arguments] }
  let(:callback)     { -> {} }
  let(:item_one) do
    { 'jid'   => jid_one,
      'class' => worker_class.to_s,
      'queue' => queue,
      'lock'  => unique,
      'args'  => args }
  end
  let(:item_two) do
    { 'jid'   => jid_two,
      'class' => worker_class.to_s,
      'queue' => queue,
      'lock'  => unique,
      'args'  => args }
  end

  before do
    allow(callback).to receive(:call).and_call_original
  end

  describe '#lock' do
    it_behaves_like 'a lock implementation'
  end

  describe '#execute' do
    it_behaves_like 'an executing lock implementation'

    it 'keeps lock after executing' do
      process_one.lock
      process_one.execute {}
      expect(process_one).to be_locked
      expect(ttl('uniquejobs:da6005926a8457526e998f0033901dfc:EXISTS')).to eq(1)
    end
  end

  describe '#unlock' do
    context 'when lock is locked' do
      before { process_one.lock }

      it 'keeps the lock even when unlocking' do
        expect(process_one.unlock).to eq(true)
        expect(process_one).to be_locked
      end
    end

    it { expect(process_one.unlock).to eq(true) }
  end
end
